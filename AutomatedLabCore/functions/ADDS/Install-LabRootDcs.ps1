function Install-LabRootDcs
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

    $machines = Get-LabVM -Role RootDC | Where-Object { -not $_.SkipDeployment }

    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role 'RootDC'" -Type Warning
        Write-LogFunctionExit
        return
    }


    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName RootDC -Wait -DoNotUseCredSsp -ProgressIndicator 10 -PostDelaySeconds 5

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

    $jobs = @()
    if ($machines)
    {
        Invoke-LabCommand -ComputerName $machines -ActivityName "Create folder 'C:\DeployDebug' for debug info" -NoDisplay -ScriptBlock {
            New-Item -ItemType Directory -Path 'c:\DeployDebug' -ErrorAction SilentlyContinue | Out-Null

            $acl = Get-Acl -Path C:\DeployDebug
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('Everyone', 'Read', 'ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
            Set-Acl -Path C:\DeployDebug -AclObject $acl
        } -DoNotUseCredSsp -UseLocalCredential

        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -eq 'RootDC'

            if ($machine.OperatingSystem.Version -lt 6.2)
            {
                #Pre 2012
                $scriptblock = $adInstallRootDcScriptPre2012
                $forestFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$dcRole.Properties.ForestFunctionalLevel
                $domainFunctionalLevel = [int][AutomatedLab.ActiveDirectoryFunctionalLevel]$dcRole.Properties.DomainFunctionalLevel
            }
            else
            {
                $scriptblock = $adInstallRootDcScript2012
                $forestFunctionalLevel = $dcRole.Properties.ForestFunctionalLevel
                $domainFunctionalLevel = $dcRole.Properties.DomainFunctionalLevel
            }

            $netBiosDomainName = if ($dcRole.Properties.ContainsKey('NetBiosDomainName'))
            {
                $dcRole.Properties.NetBiosDomainName
            }
            else
            {
                $machine.DomainName.Substring(0, $machine.DomainName.IndexOf('.'))
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
            -ActivityName "Install Root DC ($($machine.name))" `
            -AsJob `
            -UseLocalCredential `
            -DoNotUseCredSsp `
            -PassThru `
            -NoDisplay `
            -ScriptBlock $scriptblock `
            -ArgumentList $machine.DomainName,
            $machine.InstallationUser.Password,
            $forestFunctionalLevel,
            $domainFunctionalLevel,
            $netBiosDomainName,
            $DatabasePath,
            $LogPath,
            $SysvolPath,
            $DsrmPassword
        }


        Write-ScreenInfo -Message 'Waiting for Root Domain Controllers to complete installation of Active Directory and restart' -NoNewLine

        $machinesToStart = @()
        $machinesToStart += Get-LabVM -Role FirstChildDC, DC
        #starting machines in a multi net environment may not work
        if (-not (Get-LabVM -Role Routing))
        {
            $machinesToStart += Get-LabVM | Where-Object { -not $_.IsDomainJoined }
        }

        # Creating sessions from a Linux host requires the correct user name.
        # By setting HasDomainJoined to $true we ensure that not the local, but the domain admin cred is returned
        foreach ($machine in $machines)
        {
            $machine.HasDomainJoined = $true
        }

        if ($lab.DefaultVirtualizationEngine -ne 'Azure')
        {
            Wait-LabVMRestart -ComputerName $machines.Name -StartMachinesWhileWaiting $machinesToStart -DoNotUseCredSsp -ProgressIndicator 30 -TimeoutInMinutes $DcPromotionRestartTimeout -ErrorAction Stop -MonitorJob $jobs -NoNewLine
            Write-ScreenInfo -Message done

            Write-ScreenInfo -Message 'Root Domain Controllers have now restarted. Waiting for Active Directory to start up' -NoNewLine

            Wait-LabVM -ComputerName $machines -DoNotUseCredSsp -TimeoutInMinutes 30 -ProgressIndicator 30 -NoNewLine
        }
        Wait-LabADReady -ComputerName $machines -TimeoutInMinutes $AdwsReadyTimeout -ErrorAction Stop -ProgressIndicator 30 -NoNewLine

        #Create reverse lookup zone (forest scope)
        foreach ($network in ((Get-LabVirtualNetworkDefinition).AddressSpace.IpAddress.AddressAsString))
        {
            Invoke-LabCommand -ActivityName 'Create reverse lookup zone' -ComputerName $machines[0] -ScriptBlock {
                param
                (
                    [string]$ip
                )

                $zoneName = "$($ip.split('.')[2]).$($ip.split('.')[1]).$($ip.split('.')[0]).in-addr.arpa"
                dnscmd . /ZoneAdd "$zoneName" /DsPrimary /DP /forest
                dnscmd . /Config "$zoneName" /AllowUpdate 2
                ipconfig.exe -registerdns
            } -ArgumentList $network -NoDisplay
        }


        #Make sure the specified installation user will be forest admin
        Invoke-LabCommand -ActivityName 'Make installation user Domain Admin' -ComputerName $machines -ScriptBlock {
            $PSDefaultParameterValues = @{
                '*-AD*:Server' = $env:COMPUTERNAME
            }

            $user = Get-ADUser -Identity ([System.Security.Principal.WindowsIdentity]::GetCurrent().User) -Server localhost

            Add-ADGroupMember -Identity 'Domain Admins' -Members $user -Server localhost
            Add-ADGroupMember -Identity 'Enterprise Admins' -Members $user -Server localhost
            Add-ADGroupMember -Identity 'Schema Admins' -Members $user -Server localhost
        } -NoDisplay -ErrorAction SilentlyContinue

        #Non-domain-joined machine are not registered in DNS hence cannot be found from inside the lab.
        #creating an A record for each non-domain-joined machine in the first forst solves that.
        #Every non-domain-joined machine get the first forest's name as the primary DNS domain.
        $dnsCmd = Get-LabVM -All -IncludeLinux | Where-Object { -not $_.IsDomainJoined -and $_.IpV4Address } | ForEach-Object {
            "dnscmd /recordadd $(@($rootDomains)[0]) $_ A $($_.IpV4Address)`n"
        }
        $dnsCmd += "Restart-Service -Name DNS -WarningAction SilentlyContinue`n"
        Invoke-LabCommand -ActivityName 'Register non domain joined machines in DNS' -ComputerName $machines[0]`
        -ScriptBlock ([scriptblock]::Create($dnsCmd)) -NoDisplay

        Invoke-LabCommand -ActivityName 'Add flat domain name DNS record to speed up start of gpsvc in 2016' -ComputerName $machines -ScriptBlock {
            $machine = $args[0] | Where-Object { $_.Name -eq $env:COMPUTERNAME }
            dnscmd localhost /recordadd $env:USERDNSDOMAIN $env:USERDOMAIN A $machine.IpV4Address
        } -ArgumentList $machines -NoDisplay

        # Configure DNS forwarders for Azure machines to be able to mount LabSoures
        Install-LabDnsForwarder

        $linuxMachines = Get-LabVM -All -IncludeLinux | Where-Object -Property OperatingSystemType -eq 'Linux'

        if ($linuxMachines)
        {
            $rootDomains = $machines | Group-Object -Property DomainName
            foreach($root in $rootDomains)
            {
                $domainJoinedMachines = ($linuxMachines | Where-Object DomainName -eq $root.Name).Name
                if (-not $domainJoinedMachines) { continue }
                $oneTimePassword = ($root.Group)[0].InstallationUser.Password
                Invoke-LabCommand -ActivityName 'Add computer objects for domain-joined Linux machines' -ComputerName ($root.Group)[0] -ScriptBlock {
                    foreach ($m in $domainJoinedMachines) { New-ADComputer -Name $m -AccountPassword ($oneTimePassword | ConvertTo-SecureString -AsPlaintext -Force)}
                } -Variable (Get-Variable -Name domainJoinedMachines,oneTimePassword) -NoDisplay
            }
        }

        Enable-LabVMRemoting -ComputerName $machines

        #Restart the Network Location Awareness service to ensure that Windows Firewall Profile is 'Domain'
        Restart-ServiceResilient -ComputerName $machines -ServiceName nlasvc -NoNewLine

        #DNS client configuration is change by DCpromo process. Change this back
        Reset-DNSConfiguration -ComputerName (Get-LabVM -Role RootDC) -ProgressIndicator 30 -NoNewLine

        #Need to make sure that A records for domain is registered
        Write-PSFMessage -Message 'Restarting DNS and Netlogon service on Root Domain Controllers'
        $jobs = @()
        foreach ($dc in (@(Get-LabVM -Role RootDC)))
        {
            $jobs += Sync-LabActiveDirectory -ComputerName $dc -ProgressIndicator 5 -AsJob -Passthru
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoDisplay -NoNewLine

        foreach ($machine in $machines)
        {
            $dcRole = $machine.Roles | Where-Object Name -like '*DC'

            if ($dcRole.Properties.SiteName)
            {
                New-LabADSite -ComputerName $machine -SiteName $dcRole.Properties.SiteName -SiteSubnet $dcRole.Properties.SiteSubnet
                Move-LabDomainController -ComputerName $machine -SiteName $dcRole.Properties.SiteName
            }

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
        Write-ScreenInfo -Message 'All Root Domain Controllers are already installed' -Type Warning -TaskEnd
        return
    }
    Get-PSSession | Where-Object { $_.Name -ne 'WinPSCompatSession' -and $_.State -ne 'Disconnected'} | Remove-PSSession

    #this sections is required to join all machines to the domain. This is happening when starting the machines, that's why all machines are started.
    $domains = $machines.DomainName
    $filterScript = {-not $_.SkipDeployment -and 'RootDC' -notin $_.Roles.Name -and 'FirstChildDC' -notin $_.Roles.Name -and 'DC' -notin $_.Roles.Name -and
    -not $_.HasDomainJoined -and $_.DomainName -in $domains -and $_.HostType -eq 'Azure' }
    $retries = 3

    while ((Get-LabVM | Where-Object -FilterScript $filterScript) -and $retries -ge 0 )
    {
        $machinesToJoin = Get-LabVM | Where-Object -FilterScript $filterScript

        Write-ScreenInfo -Message ''
        Write-ScreenInfo "Restarting the $($machinesToJoin.Count) machines to complete the domain join of ($($machinesToJoin.Name -join ', ')). Retries remaining = $retries"
        Restart-LabVM -ComputerName $machinesToJoin -Wait -NoNewLine
        $retries--
    }
    Write-ProgressIndicatorEnd

    Write-LogFunctionExit
}
