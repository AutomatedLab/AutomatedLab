function Install-LabFirstChildDcs
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

    $machines = Get-LabVM -Role FirstChildDC | Where-Object { -not $_.SkipDeployment }
    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role 'FirstChildDC'" -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName FirstChildDC -Wait -DoNotUseCredSsp -ProgressIndicator 15 -PostDelaySeconds 5

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

        $jobs = @()
        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -eq 'FirstChildDc'

            $parentDomainName = $dcRole.Properties['ParentDomain']
            $newDomainName = $dcRole.Properties['NewDomain']
            $domainFunctionalLevel = $dcRole.Properties['DomainFunctionalLevel']
            $parentDomain = $lab.Domains | Where-Object Name -eq $parentDomainName

            #get the root domain to build the root domain credentials
            if (-not $parentDomain)
            {
                throw "New domain '$newDomainName' could not be installed. The root domain ($parentDomainName) could not be found in the lab"
            }
            $rootCredential = $parentDomain.GetCredential()

            #if there is a '.' inside the domain name, it is a new domain tree, otherwise a child domain hence we need to
            #create a DNS zone for the child domain in the parent domain
            if ($NewDomainName.Contains('.'))
            {
                $parentDc = Get-LabVM -Role RootDC, FirstChildDC | Where-Object DomainName -eq $ParentDomainName
                Write-PSFMessage -Message "Setting up a new domain tree hence creating a stub zone on Domain Controller '$($parentDc.Name)'"

                $cmd = "dnscmd . /zoneadd $NewDomainName /dsstub $((Get-LabVM -Role RootDC,FirstChildDC,DC | Where-Object DomainName -eq $NewDomainName).IpV4Address -join ', ') /dp /forest"

                Invoke-LabCommand -ActivityName 'Add DNS zones' -ComputerName $parentDc -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
                Invoke-LabCommand -ActivityName 'Restart DNS' -ComputerName $parentDc -ScriptBlock { Restart-Service -Name Dns } -NoDisplay
            }

            Write-PSFMessage -Message 'Invoking script block for DC installation and promotion'
            if ($machine.OperatingSystem.Version -lt 6.2)
            {
                $scriptBlock = $adInstallFirstChildDcPre2012
                $domainFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$domainFunctionalLevel
            }
            else
            {
                $scriptBlock = $adInstallFirstChildDc2012
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

            $jobs += Invoke-LabCommand -ComputerName $machine.Name `
            -ActivityName "Install FirstChildDC ($($machine.Name))" `
            -AsJob `
            -PassThru `
            -UseLocalCredential `
            -NoDisplay `
            -ScriptBlock $scriptBlock `
            -ArgumentList $newDomainName,
            $parentDomainName,
            $rootCredential,
            $domainFunctionalLevel,
            7,
            120,
            $siteName,
            $dcRole.Properties.NetBiosDomainName,
            $DatabasePath,
            $LogPath,
            $SysvolPath,
            $DsrmPassword
        }


        Write-ScreenInfo -Message 'Waiting for First Child Domain Controllers to complete installation of Active Directory and restart' -NoNewline

        $domains = @((Get-LabVM -Role RootDC).DomainName)
        foreach ($domain in $domains)
        {
            if (Get-LabVM -Role DC | Where-Object DomainName -eq $domain)
            {
                $domains = $domain | Where-Object { $_ -ne $domain }
            }
        }

        $machinesToStart = @()
        $machinesToStart += Get-LabVM -Role DC
        #starting machines in a multi net environment may not work at this point of the deployment
        if (-not (Get-LabVM -Role Routing))
        {
            $machinesToStart += Get-LabVM | Where-Object { -not $_.IsDomainJoined }
            $machinesToStart += Get-LabVM | Where-Object DomainName -in $domains
        }

        # Creating sessions from a Linux host requires the correct user name.
        # By setting HasDomainJoined to $true we ensure that not the local, but the domain admin cred is returned
        foreach ($machine in $machines)
        {
            $machine.HasDomainJoined = $true
        }

        if ($lab.DefaultVirtualizationEngine -ne 'Azure')
        {
            Wait-LabVMRestart -ComputerName $machines.name -StartMachinesWhileWaiting $machinesToStart -ProgressIndicator 45 -TimeoutInMinutes $DcPromotionRestartTimeout -ErrorAction Stop -MonitorJob $jobs -NoNewLine
            Write-ScreenInfo done

            Write-ScreenInfo -Message 'First Child Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine

            #Wait a little to be able to connect in first attempt
            Wait-LWLabJob -Job (Start-Job -Name 'Delay waiting for machines to be reachable' -ScriptBlock { Start-Sleep -Seconds 60 }) -ProgressIndicator 20 -NoDisplay -NoNewLine

            Wait-LabVM -ComputerName $machines -TimeoutInMinutes 30 -ProgressIndicator 20 -NoNewLine
        }
        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 20 -NoNewLine

        #Make sure the specified installation user will be domain admin
        Invoke-LabCommand -ActivityName 'Make installation user Domain Admin' -ComputerName $machines -ScriptBlock {
            $PSDefaultParameterValues = @{
                '*-AD*:Server' = $env:COMPUTERNAME
            }

            $user = Get-ADUser -Identity ([System.Security.Principal.WindowsIdentity]::GetCurrent().User)

            Add-ADGroupMember -Identity 'Domain Admins' -Members $user
        } -NoDisplay

        Invoke-LabCommand -ActivityName 'Add flat domain name DNS record to speed up start of gpsvc in 2016' -ComputerName $machines -ScriptBlock {
            $machine = $args[0] | Where-Object { $_.Name -eq $env:COMPUTERNAME }
            dnscmd localhost /recordadd $env:USERDNSDOMAIN $env:USERDOMAIN A $machine.IpV4Address
        } -ArgumentList $machines -NoDisplay

        Restart-LabVM -ComputerName $machines -Wait -NoDisplay -NoNewLine
        Wait-LabADReady -ComputerName $machines -NoNewLine

        Enable-LabVMRemoting -ComputerName $machines

        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine

        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabVM -Role FirstChildDC) -ProgressIndicator 20 -NoNewLine

        Write-PSFMessage -Message 'Restarting DNS and Netlogon services on Root and Child Domain Controllers and triggering replication'
        $jobs = @()
        foreach ($dc in (@(Get-LabVM -Role RootDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        $jobs = @()
        foreach ($dc in (@(Get-LabVM -Role FirstChildDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 20 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 20 -NoDisplay -NoNewLine
        
        foreach ($machine in $machines)
        {
            Reset-LabAdPassword -DomainName $machine.DomainName
            Remove-LabPSSession -ComputerName $machine
            Enable-LabAutoLogon -ComputerName $machine
        }

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
        Write-ScreenInfo -Message 'All First Child Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }

    Get-PSSession | Where-Object { $_.Name -ne 'WinPSCompatSession' -and $_.State -ne 'Disconnected'} | Remove-PSSession

    #this sections is required to join all machines to the domain. This is happening when starting the machines, that's why all machines are started.
    $domains = $machines.DomainName
    $filterScript = {-not $_.SkipDeployment -and 'RootDC' -notin $_.Roles.Name -and 'FirstChildDC' -notin $_.Roles.Name -and 'DC' -notin $_.Roles.Name -and
    -not $_.HasDomainJoined -and $_.DomainName -in $domains -and $_.HostType -eq 'Azure' }
    $retries = 3

    while ((Get-LabVM | Where-Object -FilterScript $filterScript) -or $retries -le 0 )
    {
        $machinesToJoin = Get-LabVM | Where-Object -FilterScript $filterScript

        Write-ScreenInfo "Restarting the $($machinesToJoin.Count) machines to complete the domain join of ($($machinesToJoin.Name -join ', ')). Retries remaining = $retries"
        Restart-LabVM -ComputerName $machinesToJoin -Wait
        $retries--
    }

    Write-ProgressIndicatorEnd
    Write-LogFunctionExit
}
