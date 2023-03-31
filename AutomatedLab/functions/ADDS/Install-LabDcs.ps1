function Install-LabDcs
{
    [CmdletBinding()]
    param (
        [int]$DcPromotionRestartTimeout = (Get-LabConfigurationItem -Name Timeout_DcPromotionRestartAfterDcpromo),

        [int]$AdwsReadyTimeout = (Get-LabConfigurationItem -Name Timeout_DcPromotionAdwsReady),

        [switch]$CreateCheckPoints,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator)
    )

    Write-LogFunctionEntry

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -Role DC | Where-Object { -not $_.SkipDeployment }

    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role 'DC'" -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName DC -Wait -DoNotUseCredSsp -ProgressIndicator 15 -PostDelaySeconds 5

    #Determine if any machines are already installed as Domain Controllers and exclude these
    $machinesAlreadyInstalled = foreach ($machine in $machines)
    {
        if (Test-LabADReady -ComputerName $machine)
        {
            $machine.Name
        }
    }

    $machines = $machines | Where-Object Name -notin $machinesAlreadyInstalled
    foreach ($m in $machinesAlreadyInstalled)
    {
        Write-ScreenInfo -Message "Machine '$m' is already a Domain Controller. Skipping this machine." -Type Warning
    }

    if ($machines)
    {
        Invoke-LabCommand -ComputerName $machines -ActivityName "Create folder 'C:\DeployDebug' for debug info" -NoDisplay -ScriptBlock {
            New-Item -ItemType Directory -Path 'c:\DeployDebug' -ErrorAction SilentlyContinue | Out-Null

            $acl = Get-Acl -Path C:\DeployDebug
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'Read', 'ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
            Set-Acl -Path C:\DeployDebug -AclObject $acl
        } -DoNotUseCredSsp -UseLocalCredential

        $rootDcs = Get-LabVM -Role RootDC
        $childDcs = Get-LabVM -Role FirstChildDC

        $jobs = @()

        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -like '*DC'

            $isReadOnly = $dcRole.Properties['IsReadOnly']
            if ($isReadOnly -eq 'true')
            {
                $isReadOnly = $true
            }
            else
            {
                $isReadOnly = $false
            }

            #get the root domain to build the root domain credentials
            $parentDc = Get-LabVM -Role RootDC | Where-Object DomainName -eq $lab.GetParentDomain($machine.DomainName).Name
            $parentCredential = $parentDc.GetCredential((Get-Lab))

            Write-PSFMessage -Message 'Invoking script block for DC installation and promotion'
            if ($machine.OperatingSystem.Version -lt 6.2)
            {
                $scriptblock = $adInstallDcPre2012
            }
            else
            {
                $scriptblock = $adInstallDc2012
            }

            $siteName = 'Default-First-Site-Name'

            if ($dcRole.Properties.SiteName)
            {
                $siteName = $dcRole.Properties.SiteName
                New-LabADSite -ComputerName $machine -SiteName $siteName -SiteSubnet $dcRole.Properties.SiteSubnet
            }

            $databasePath = if ($dcRole.Properties.ContainsKey('DatabasePath'))
            {
                $dcRole.Properties.DatabasePath
            }
            else
            {
                'C:\Windows\NTDS'
            }

            $logPath = if ($dcRole.Properties.ContainsKey('LogPath'))
            {
                $dcRole.Properties.LogPath
            }
            else
            {
                'C:\Windows\NTDS'
            }

            $sysvolPath = if ($dcRole.Properties.ContainsKey('SysvolPath'))
            {
                $dcRole.Properties.SysvolPath
            }
            else
            {
                'C:\Windows\Sysvol'
            }

            $dsrmPassword = if ($dcRole.Properties.ContainsKey('DsrmPassword'))
            {
                $dcRole.Properties.DsrmPassword
            }
            else
            {
                $machine.InstallationUser.Password
            }

            #only print out warnings if verbose logging is enabled
            $WarningPreference = $VerbosePreference

            $jobs += Invoke-LabCommand -ComputerName $machine `
            -ActivityName "Install DC ($($machine.name))" `
            -AsJob `
            -PassThru `
            -UseLocalCredential `
            -NoDisplay `
            -ScriptBlock $scriptblock `
            -ArgumentList $machine.DomainName,
            $parentCredential,
            $isReadOnly,
            7,
            120,
            $siteName,
            $DatabasePath,
            $LogPath,
            $SysvolPath,
            $DsrmPassword
        }

        Write-ScreenInfo -Message 'Waiting for additional Domain Controllers to complete installation of Active Directory and restart' -NoNewLine

        $domains = (Get-LabVM -Role DC).DomainName

        $machinesToStart = @()
        #starting machines in a multi net environment may not work
        if (-not (Get-LabVM -Role Routing))
        {
            $machinesToStart += Get-LabVM | Where-Object { -not $_.IsDomainJoined }
            $machinesToStart += Get-LabVM | Where-Object DomainName -notin $domains
        }

        # Creating sessions from a Linux host requires the correct user name.
        # By setting HasDomainJoined to $true we ensure that not the local, but the domain admin cred is returned
        foreach ($machine in $machines)
        {
            $machine.HasDomainJoined = $true
        }

        if ($lab.DefaultVirtualizationEngine -ne 'Azure')
        {
            Wait-LabVMRestart -ComputerName $machines -StartMachinesWhileWaiting $machinesToStart -TimeoutInMinutes $DcPromotionRestartTimeout -MonitorJob $jobs -ProgressIndicator 60 -NoNewLine -ErrorAction Stop
            Write-ScreenInfo -Message done

            Write-ScreenInfo -Message 'Additional Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine

            #Wait a little to be able to connect in first attempt
            Wait-LWLabJob -Job (Start-Job -Name 'Delay waiting for machines to be reachable' -ScriptBlock {
                    Start-Sleep -Seconds 60
            }) -ProgressIndicator 20 -NoDisplay -NoNewLine

            Wait-LabVM -ComputerName $machines -TimeoutInMinutes 30 -ProgressIndicator 20 -NoNewLine
        }

        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 20 -NoNewLine

        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine

        Enable-LabVMRemoting -ComputerName $machines
        Enable-LabAutoLogon -ComputerName $machines

        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabVM -Role DC) -ProgressIndicator 20 -NoNewLine

        Write-PSFMessage -Message 'Restarting DNS and Netlogon services on all Domain Controllers and triggering replication'
        $jobs = @()
        foreach ($dc in (Get-LabVM -Role RootDC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (Get-LabVM -Role FirstChildDC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (Get-LabVM -Role DC))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        Write-ProgressIndicatorEnd

        if ($CreateCheckPoints)
        {
            foreach ($machine in ($machines | Where-Object HostType -eq 'HyperV'))
            {
                Checkpoint-LWVM -ComputerName $machine -SnapshotName 'Post DC Promotion'
            }
        }
    }
    else
    {
        Write-ScreenInfo -Message 'All additional Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }

    Get-PSSession | Where-Object { $_.Name -ne 'WinPSCompatSession' -and $_.State -ne 'Disconnected'} | Remove-PSSession

    Write-LogFunctionExit
}
