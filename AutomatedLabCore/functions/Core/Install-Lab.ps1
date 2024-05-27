function Install-Lab
{
    [cmdletBinding()]
    param (
        [switch]$NetworkSwitches,
        [switch]$BaseImages,
        [switch]$VMs,
        [switch]$Domains,
        [switch]$AdTrusts,
        [switch]$DHCP,
        [switch]$Routing,
        [switch]$PostInstallations,
        [switch]$SQLServers,
        [switch]$Orchestrator2012,
        [switch]$WebServers,
        [Alias('Sharepoint2013')]
        [switch]$SharepointServer,
        [switch]$CA,
        [switch]$ADFS,
        [switch]$DSCPullServer,
        [switch]$VisualStudio,
        [switch]$Office2013,
        [switch]$Office2016,
        [switch]$AzureServices,
        [switch]$TeamFoundation,
        [switch]$FailoverStorage,
        [switch]$FailoverCluster,
        [switch]$FileServer,
        [switch]$HyperV,
        [switch]$WindowsAdminCenter,
        [switch]$Scvmm,
        [switch]$Scom,
        [switch]$Dynamics,
        [switch]$RemoteDesktop,
        [switch]$ConfigurationManager,
        [switch]$StartRemainingMachines,
        [switch]$CreateCheckPoints,
        [switch]$InstallRdsCertificates,
        [switch]$InstallSshKnownHosts,
        [switch]$PostDeploymentTests,
        [switch]$NoValidation,
        [int]$DelayBetweenComputers
    )

    Write-LogFunctionEntry
    $global:PSLog_Indent = 0

    $labDiskDeploymentInProgressPath = Get-LabConfigurationItem -Name DiskDeploymentInProgressPath

    #perform full install if no role specific installation is requested
    $performAll = -not ($PSBoundParameters.Keys | Where-Object { $_ -notin ('NoValidation', 'DelayBetweenComputers' + [System.Management.Automation.Internal.CommonParameters].GetProperties().Name)}).Count

    if (-not $Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        Export-LabDefinition -Force -ExportDefaultUnattendedXml

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    if ($Global:labExported -and -not (Get-Lab -ErrorAction SilentlyContinue))
    {
        if ($NoValidation)
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath -NoValidation
        }
        else
        {
            Import-Lab -Path (Get-LabDefinition).LabFilePath
        }
    }

    if (-not $Script:data)
    {
        Write-Error 'No definitions imported, so there is nothing to test. Please use Import-Lab against the xml file'
        return
    }

    try
    {
        [AutomatedLab.LabTelemetry]::Instance.LabStarted((Get-Lab).Export(), (Get-Module AutomatedLabCore)[-1].Version, $PSVersionTable.BuildVersion, $PSVersionTable.PSVersion)
    }
    catch
    {
        # Nothing to catch - if an error occurs, we simply do not get telemetry.
        Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
    }

    Unblock-LabSources

    Send-ALNotification -Activity 'Lab started' -Message ('Lab deployment started with {0} machines' -f (Get-LabVM).Count) -Provider (Get-LabConfigurationItem -Name Notifications.SubscribedProviders)
    $engine = $Script:data.DefaultVirtualizationEngine

    if (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV')
    {
        Update-LabMemorySettings
    }

    if ($engine -ne 'Azure' -and ($NetworkSwitches -or $performAll))
    {
        Write-ScreenInfo -Message 'Creating virtual networks' -TaskStart

        New-LabNetworkSwitches

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($BaseImages -or $performAll) -and (Get-LabVM -All | Where-Object HostType -eq 'HyperV'))
    {
        try
        {
            if (Test-Path -Path $labDiskDeploymentInProgressPath)
            {
                Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
                Write-ScreenInfo 'Waiting until other disk deployment is finished.' -NoNewLine
                do
                {
                    Write-ScreenInfo -Message . -NoNewLine
                    Start-Sleep -Seconds 15
                } while (Test-Path -Path $labDiskDeploymentInProgressPath)
            }
            Write-ScreenInfo 'done'

            Write-ScreenInfo -Message 'Creating base images' -TaskStart

            New-Item -Path $labDiskDeploymentInProgressPath -ItemType File -Value ($Script:data).Name | Out-Null

            New-LabBaseImages

            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        finally
        {
            Remove-Item -Path $labDiskDeploymentInProgressPath -Force
        }
    }

    if ($VMs -or $performAll)
    {
        try
        {
            if ((Test-Path -Path $labDiskDeploymentInProgressPath) -and (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV'))
            {
                Write-ScreenInfo "Another lab disk deployment seems to be in progress. If this is not correct, please delete the file '$labDiskDeploymentInProgressPath'." -Type Warning
                Write-ScreenInfo 'Waiting until other disk deployment is finished.' -NoNewLine
                do
                {
                    Write-ScreenInfo -Message . -NoNewLine
                    Start-Sleep -Seconds 15
                } while (Test-Path -Path $labDiskDeploymentInProgressPath)
            }
            Write-ScreenInfo 'done'

            if (Get-LabVM -All -IncludeLinux | Where-Object HostType -eq 'HyperV')
            {
                Write-ScreenInfo -Message 'Creating Additional Disks' -TaskStart
                New-Item -Path $labDiskDeploymentInProgressPath -ItemType File -Value ($Script:data).Name | Out-Null
                New-LabVHDX
                Write-ScreenInfo -Message 'Done' -TaskEnd
            }

            Write-ScreenInfo -Message 'Creating VMs' -TaskStart
            #add a hosts entry for each lab machine
            $hostFileAddedEntries = 0
            foreach ($machine in ($Script:data.Machines | Where-Object { [string]::IsNullOrEmpty($_.FriendlyName) }))
            {
                if ($machine.HostType -ne 'HyperV' -or (Get-LabConfigurationItem -Name SkipHostFileModification))
                {
                    continue
                }
                $defaultNic = $machine.NetworkAdapters | Where-Object Default
                $addresses = if ($defaultNic)
                {
                    ($defaultNic | Select-Object -First 1).Ipv4Address.IpAddress.AddressAsString
                }
                if (-not $addresses)
                {
                    $addresses = @($machine.NetworkAdapters[0].Ipv4Address.IpAddress.AddressAsString)
                }

                if (-not $addresses)
                {
                    continue
                }

                #only the first addredd of a machine is added as for local connectivity the other addresses don't make a difference
                $hostFileAddedEntries += Add-HostEntry -HostName $machine.Name -IpAddress $addresses[0] -Section $Script:data.Name
                $hostFileAddedEntries += Add-HostEntry -HostName $machine.FQDN -IpAddress $addresses[0] -Section $Script:data.Name
            }

            if ($hostFileAddedEntries)
            {
                Write-ScreenInfo -Message "The hosts file has been updated with $hostFileAddedEntries records. Clean them up using 'Remove-Lab' or manually if needed" -Type Warning
            }

            if ($script:data.Machines | Where-Object SkipDeployment -eq $false)
            {
                New-LabVM -Name ($script:data.Machines | Where-Object SkipDeployment -eq $false) -CreateCheckPoints:$CreateCheckPoints
            }

            #VMs created, export lab definition again to update MAC addresses
            Set-LabDefinition -Machines $Script:data.Machines
            Export-LabDefinition -Force -ExportDefaultUnattendedXml -Silent

            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        finally
        {
            Remove-Item -Path $labDiskDeploymentInProgressPath -Force -ErrorAction SilentlyContinue
        }
    }

    #Root DCs are installed first, then the Routing role is installed in order to allow domain joined routers in the root domains
    if (($Domains -or $performAll) -and (Get-LabVM -Role RootDC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Root Domain Controllers' -TaskStart
        foreach ($azVm in (Get-LabVM -IncludeLinux -Filter {$_.HostType -eq 'Azure'}))
        {
            $nicCount = 0
            foreach ($azNic in $azVm.NetworkAdapters)
            {
                $dns = ($Lab.VirtualNetworks | Where-Object ResourceName -eq $azNic.VirtualSwitch).DnsServers.AddressAsString
                if ($nic.Ipv4DnsServers.AddressAsString) {$dns = $nic.Ipv4DnsServers.AddressAsString}
                if ($dns.Count -eq 0) { continue }
                # Set NIC configured DNS
                [string]$vmNicId = (Get-LWAzureVm -ComputerName $azVm.ResourceName).NetworkProfile.NetworkInterfaces.Id.Where({$_.EndsWith("nic$nicCount")})
                $vmNic = Get-AzNetworkInterface -ResourceId $vmNicId
                if ($dns -and $vmNic.DnsSettings.DnsServers -and -not (Compare-Object -ReferenceObject $dns -DifferenceObject $vmNic.DnsSettings.DnsServers)) { continue }

                $vmNic.DnsSettings.DnsServers = [Collections.Generic.List[string]]$dns
                $null = $vmNic | Set-AzNetworkInterface
                $nicCount++
            }
        }

        foreach ($azNet in ((Get-Lab).VirtualNetworks | Where HostType -eq 'Azure'))
        {
            # Set VNET DNS
            if ($null -eq $aznet.DnsServers.AddressAsString) { continue }

            $net = Get-AzVirtualNetwork -Name $aznet.ResourceName
            if (-not $net.DhcpOptions)
            {
                $net.DhcpOptions = @{}
            }

            $net.DhcpOptions.DnsServers = [Collections.Generic.List[string]]$aznet.DnsServers.AddressAsString
            $null = $net | Set-AzVirtualNetwork
        }

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role RootDC | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message "Machines with RootDC role to be installed: '$((Get-LabVM -Role RootDC).Name -join ', ')'"
        Install-LabRootDcs -CreateCheckPoints:$CreateCheckPoints
        
        New-LabADSubnet

        # Set account expiration for builtin account and lab domain account
        foreach ($machine in (Get-LabVM -Role RootDC -ErrorAction SilentlyContinue))
        {
            $userName = (Get-Lab).Domains.Where({ $_.Name -eq $machine.DomainName }).Administrator.UserName
            Invoke-LabCommand -ActivityName 'Setting PasswordNeverExpires for deployment accounts in AD' -ComputerName $machine -ScriptBlock {
                Set-ADUser -Identity $userName -PasswordNeverExpires $true -Confirm:$false
            } -Variable (Get-Variable userName) -NoDisplay
        }

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Routing -or $performAll) -and (Get-LabVM -Role Routing | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Configuring routing' -TaskStart

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Routing | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabRouting

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($DHCP -or $performAll) -and (Get-LabVM -Role DHCP | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Configuring DHCP servers' -TaskStart

        #Install-DHCP
        Write-Error 'The DHCP role is not implemented yet'

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Domains -or $performAll) -and (Get-LabVM -Role FirstChildDC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Child Domain Controllers' -TaskStart

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role FirstChildDC | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Write-ScreenInfo -Message "Machines with FirstChildDC role to be installed: '$((Get-LabVM -Role FirstChildDC).Name -join ', ')'"
        Install-LabFirstChildDcs -CreateCheckPoints:$CreateCheckPoints

        New-LabADSubnet

        $allDcVMs = Get-LabVM -Role RootDC, FirstChildDC | Where-Object { -not $_.SkipDeployment }

        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Domains -or $performAll) -and (Get-LabVM -Role DC | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Additional Domain Controllers' -TaskStart

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role DC | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Write-ScreenInfo -Message "Machines with DC role to be installed: '$((Get-LabVM -Role DC).Name -join ', ')'"
        Install-LabDcs -CreateCheckPoints:$CreateCheckPoints

        New-LabADSubnet

        $allDcVMs = Get-LabVM -Role RootDC, FirstChildDC, DC | Where-Object { -not $_.SkipDeployment }

        if ($allDcVMs)
        {
            if ($CreateCheckPoints)
            {
                Write-ScreenInfo -Message 'Creating a snapshot of all domain controllers'
                Checkpoint-LabVM -ComputerName $allDcVMs -SnapshotName 'Post Forest Setup'
            }
        }

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($AdTrusts -or $performAll) -and ((Get-LabVM -Role RootDC | Measure-Object).Count -gt 1))
    {
        Write-ScreenInfo -Message 'Configuring AD trusts' -TaskStart
        Install-LabADDSTrust
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ((Get-LabVm -Filter {-not $_.SkipDeployment -and $_.Roles.Count -eq 0}))
    {
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName (Get-LabVm -Filter {-not $_.SkipDeployment -and $_.Roles.Count -eq 0}) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
    }
    
    if (($FileServer -or $performAll) -and (Get-LabVM -Role FileServer))
    {
        Write-ScreenInfo -Message 'Installing File Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role FileServer | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabFileServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($CA -or $performAll) -and (Get-LabVM -Role CaRoot, CaSubordinate))
    {
        Write-ScreenInfo -Message 'Installing Certificate Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role CaRoot,CaSubordinate | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabCA -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if(($HyperV -or $performAll) -and (Get-LabVm -Role HyperV | Where-Object {-not $_.SkipDeployment}))
    {
        Write-ScreenInfo -Message 'Installing HyperV servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role HyperV | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Install-LabHyperV

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    
    if (($FailoverStorage -or $performAll) -and (Get-LabVM -Role FailoverStorage | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Failover Storage' -TaskStart

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role FailoverStorage | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Start-LabVM -RoleName FailoverStorage -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        Install-LabFailoverStorage

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($FailoverCluster -or $performAll) -and (Get-LabVM -Role FailoverNode, FailoverStorage | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Failover Cluster' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role FailoverNode, FailoverStorage | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Start-LabVM -RoleName FailoverNode,FailoverStorage -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        Install-LabFailoverCluster

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($SQLServers -or $performAll) -and (Get-LabVM -Role SQLServer | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing SQL Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role SQLServer | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        if (Get-LabVM -Role SQLServer2008)   { Write-ScreenInfo -Message "Machines to have SQL Server 2008 installed: '$((Get-LabVM -Role SQLServer2008).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2008R2) { Write-ScreenInfo -Message "Machines to have SQL Server 2008 R2 installed: '$((Get-LabVM -Role SQLServer2008R2).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2012)   { Write-ScreenInfo -Message "Machines to have SQL Server 2012 installed: '$((Get-LabVM -Role SQLServer2012).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2014)   { Write-ScreenInfo -Message "Machines to have SQL Server 2014 installed: '$((Get-LabVM -Role SQLServer2014).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2016)   { Write-ScreenInfo -Message "Machines to have SQL Server 2016 installed: '$((Get-LabVM -Role SQLServer2016).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2017)   { Write-ScreenInfo -Message "Machines to have SQL Server 2017 installed: '$((Get-LabVM -Role SQLServer2017).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2019)   { Write-ScreenInfo -Message "Machines to have SQL Server 2019 installed: '$((Get-LabVM -Role SQLServer2019).Name -join ', ')'" }
        if (Get-LabVM -Role SQLServer2022)   { Write-ScreenInfo -Message "Machines to have SQL Server 2022 installed: '$((Get-LabVM -Role SQLServer2022).Name -join ', ')'" }
        Install-LabSqlServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($ConfigurationManager -or $performAll) -and (Get-LabVm -Role ConfigurationManager -Filter {-not $_.SkipDeployment}))
    {
        Write-ScreenInfo -Message 'Deploying System Center Configuration Manager' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role ConfigurationManager | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabConfigurationManager
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($RemoteDesktop -or $performAll) -and (Get-LabVm -Role RDS -Filter {-not $_.SkipDeployment}))
    {
        Write-ScreenInfo -Message 'Deploying Remote Desktop Services' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role RDS | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabRemoteDesktopServices
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Dynamics -or $performAll) -and (Get-LabVm -Role Dynamics | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Dynamics' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Dynamics | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabDynamics -CreateCheckPoints:$CreateCheckPoints
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($DSCPullServer -or $performAll) -and (Get-LabVM -Role DSCPullServer | Where-Object { -not $_.SkipDeployment }))
    {
        Start-LabVM -RoleName DSCPullServer -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role DSCPullServer | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message 'Installing DSC Pull Servers' -TaskStart
        Install-LabDscPullServer

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($ADFS -or $performAll) -and (Get-LabVM -Role ADFS))
    {
        Write-ScreenInfo -Message 'Configuring ADFS' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role ADFS | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Install-LabAdfs

        Write-ScreenInfo -Message 'Done' -TaskEnd

        Write-ScreenInfo -Message 'Configuring ADFS Proxies' -TaskStart

        Install-LabAdfsProxy

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($WebServers -or $performAll) -and (Get-LabVM -Role WebServer | Where-Object { -not $_.SkipDeployment }))
    {
        Write-ScreenInfo -Message 'Installing Web Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role WebServer | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Write-ScreenInfo -Message "Machines to have Web Server role installed: '$((Get-LabVM -Role WebServer | Where-Object { -not $_.SkipDeployment }).Name -join ', ')'"
        Install-LabWebServers -CreateCheckPoints:$CreateCheckPoints

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($WindowsAdminCenter -or $performAll) -and (Get-LabVm -Role WindowsAdminCenter))
    {
        Write-ScreenInfo -Message 'Installing Windows Admin Center Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role WindowsAdminCenter | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Write-ScreenInfo -Message "Machines to have Windows Admin Center installed: '$((Get-LabVM -Role WindowsAdminCenter | Where-Object { -not $_.SkipDeployment }).Name -join ', ')'"
        Install-LabWindowsAdminCenter

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Orchestrator2012 -or $performAll) -and (Get-LabVM -Role Orchestrator2012))
    {
        Write-ScreenInfo -Message 'Installing Orchestrator Servers' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Orchestrator2012 | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabOrchestrator2012

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($SharepointServer -or $performAll) -and (Get-LabVM -Role SharePoint))
    {
        Write-ScreenInfo -Message 'Installing SharePoint Servers' -TaskStart

        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role SharePoint | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Install-LabSharePoint

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($VisualStudio -or $performAll) -and (Get-LabVM -Role VisualStudio2013))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2013' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role VisualStudio2013 | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message "Machines to have Visual Studio 2013 installed: '$((Get-LabVM -Role VisualStudio2013).Name -join ', ')'"
        Install-VisualStudio2013

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($VisualStudio -or $performAll) -and (Get-LabVM -Role VisualStudio2015))
    {
        Write-ScreenInfo -Message 'Installing Visual Studio 2015' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role VisualStudio2015 | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message "Machines to have Visual Studio 2015 installed: '$((Get-LabVM -Role VisualStudio2015).Name -join ', ')'"
        Install-VisualStudio2015

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Office2013 -or $performAll) -and (Get-LabVM -Role Office2013))
    {
        Write-ScreenInfo -Message 'Installing Office 2013' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Office2013 | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message "Machines to have Office 2013 installed: '$((Get-LabVM -Role Office2013).Name -join ', ')'"
        Install-LabOffice2013

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($Office2016 -or $performAll) -and (Get-LabVM -Role Office2016))
    {
        Write-ScreenInfo -Message 'Installing Office 2016' -TaskStart
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Office2016 | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        Write-ScreenInfo -Message "Machines to have Office 2016 installed: '$((Get-LabVM -Role Office2016).Name -join ', ')'"
        Install-LabOffice2016

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($TeamFoundation -or $performAll) -and (Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps))
    {
        Write-ScreenInfo -Message 'Installing Team Foundation Server environment'
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
        Write-ScreenInfo -Message "Machines to have TFS or the build agent installed: '$((Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps).Name -join ', ')'"

        $machinesToStart = Get-LabVM -Role Tfs2015,Tfs2017,Tfs2018,TfsBuildWorker,AzDevOps | Where-Object -Property SkipDeployment -eq $false
        if ($machinesToStart)
        {
            Start-LabVm -ComputerName $machinesToStart -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        }

        Install-LabTeamFoundationEnvironment
        Write-ScreenInfo -Message 'Team Foundation Server environment deployed'
    }

    if (($Scvmm -or $performAll) -and (Get-LabVM -Role SCVMM))
    {
        Write-ScreenInfo -Message 'Installing SCVMM'
        Write-ScreenInfo -Message "Machines to have SCVMM Management or Console installed: '$((Get-LabVM -Role SCVMM).Name -join ', ')'"
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role SCVMM | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        $machinesToStart = Get-LabVM -Role SCVMM | Where-Object -Property SkipDeployment -eq $false
        if ($machinesToStart)
        {
            Start-LabVm -ComputerName $machinesToStart -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        }

        Install-LabScvmm
        Write-ScreenInfo -Message 'SCVMM environment deployed'
    }

    if (($Scom -or $performAll) -and (Get-LabVM -Role SCOM))
    {
        Write-ScreenInfo -Message 'Installing SCOM'
        Write-ScreenInfo -Message "Machines to have SCOM components installed: '$((Get-LabVM -Role SCOM).Name -join ', ')'"
        $jobs = Invoke-LabCommand -PreInstallationActivity -ActivityName 'Pre-installation' -ComputerName $(Get-LabVM -Role SCOM | Where-Object { -not $_.SkipDeployment }) -PassThru -NoDisplay
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null

        $machinesToStart = Get-LabVM -Role SCOM | Where-Object -Property SkipDeployment -eq $false
        if ($machinesToStart)
        {
            Start-LabVm -ComputerName $machinesToStart -ProgressIndicator 15 -PostDelaySeconds 5 -Wait
        }

        Install-LabScom
        Write-ScreenInfo -Message 'SCOM environment deployed'
    }

    if (($StartRemainingMachines -or $performAll) -and (Get-LabVM -IncludeLinux | Where-Object -Property SkipDeployment -eq $false))
    {
        $linuxHosts = (Get-LabVM -IncludeLinux | Where-Object OperatingSystemType -eq 'Linux').Count
        Write-ScreenInfo -Message 'Starting remaining machines' -TaskStart
        $timeoutRemaining = 60
        if ($linuxHosts -and -not (Get-LabConfigurationItem -Name DoNotWaitForLinux -Default $false))
        {
            $timeoutRemaining = 15
            Write-ScreenInfo -Type Warning -Message "There are $linuxHosts Linux hosts in the lab.
                On Windows, those are installed from scratch and do not use differencing disks.
        
                If you did not connect them to an external switch or deploy a router in your lab,
                AutomatedLab will not be able to reach your VMs, as PowerShell will not be installed.

                The timeout to wait for VMs to be accessible via PowerShell was reduced from 60 to 15
            minutes."
        }

        if ($null -eq $DelayBetweenComputers)
        {
            $hypervMachineCount = (Get-LabVM -IncludeLinux | Where-Object HostType -eq HyperV).Count
            if ($hypervMachineCount)
            {
                $DelayBetweenComputers = [System.Math]::Log($hypervMachineCount, 5) * 30
                Write-ScreenInfo -Message "DelayBetweenComputers not defined, value calculated is $DelayBetweenComputers seconds"
            }
            else
            {
                $DelayBetweenComputers = 0
            }            
        }

        Write-ScreenInfo -Message 'Waiting for machines to start up...' -NoNewLine

        $toStart = Get-LabVM -IncludeLinux:$(-not (Get-LabConfigurationItem -Name DoNotWaitForLinux -Default $false)) | Where-Object SkipDeployment -eq $false
        Start-LabVM -ComputerName $toStart -DelayBetweenComputers $DelayBetweenComputers -ProgressIndicator 30 -TimeoutInMinutes $timeoutRemaining -Wait

        $userName = (Get-Lab).DefaultInstallationCredential.UserName
        $nonDomainControllers = Get-LabVM -Filter { $_.Roles.Name -notcontains 'RootDc' -and $_.Roles.Name -notcontains 'DC' -and $_.Roles.Name -notcontains 'FirstChildDc' -and -not $_.SkipDeployment }
        if ($nonDomainControllers) {
            Invoke-LabCommand -ActivityName 'Setting PasswordNeverExpires for local deployment accounts' -ComputerName $nonDomainControllers -ScriptBlock {
                # Still supporting ANCIENT server 2008 R2 with it's lack of CIM cmdlets :'(
                    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
                    {
                        Get-CimInstance -Query "Select * from Win32_UserAccount where name = '$userName' and localaccount='true'" | Set-CimInstance -Property @{ PasswordExpires = $false}
                    }
                    else
                    {
                        Get-WmiObject -Query "Select * from Win32_UserAccount where name = '$userName' and localaccount='true'" | Set-WmiInstance -Arguments @{ PasswordExpires = $false}
                    }
            } -Variable (Get-Variable userName) -NoDisplay
        }

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    # A new bug surfaced where on some occasion, Azure IaaS workloads were not connected to the internet
    # until a restart was done
    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        $azvms = Get-LabVm | Where-Object SkipDeployment -eq $false
        $disconnectedVms = Invoke-LabCommand -PassThru -NoDisplay -ComputerName $azvms -ScriptBlock { $null -eq (Get-NetConnectionProfile -IPv4Connectivity Internet -ErrorAction SilentlyContinue) } | Where-Object { $_}
        if ($disconnectedVms) { Restart-LabVm $disconnectedVms.PSComputerName -Wait -NoDisplay -NoNewLine }
    }

    if (($PostInstallations -or $performAll) -and (Get-LabVM | Where-Object -Property SkipDeployment -eq $false))
    {
        $machines = Get-LabVM | Where-Object { -not $_.SkipDeployment }
        $jobs = Invoke-LabCommand -PostInstallationActivity -ActivityName 'Post-installation' -ComputerName $machines -PassThru -NoDisplay
        #PostInstallations can be installed as jobs or as direct calls. If there are jobs returned, wait until they are finished
        $jobs | Where-Object { $_ -is [System.Management.Automation.Job] } | Wait-Job | Out-Null
    }

    if (($AzureServices -or $performAll) -and (Get-LabAzureWebApp))
    {
        Write-ScreenInfo -Message 'Starting deployment of Azure services' -TaskStart

        Install-LabAzureServices

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($InstallRdsCertificates -or $performAll)
    {
        Write-ScreenInfo -Message 'Installing RDS certificates of lab machines' -TaskStart
        
        Install-LabRdsCertificate
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if (($InstallSshKnownHosts -and (Get-LabVm).SshPublicKey) -or ($performAll-and (Get-LabVm).SshPublicKey))
    {
        Write-ScreenInfo -Message "Adding lab machines to $home/.ssh/known_hosts" -TaskStart
        
        Install-LabSshKnownHost
        
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    try
    {
        [AutomatedLab.LabTelemetry]::Instance.LabFinished((Get-Lab).Export())
    }
    catch
    {
        # Nothing to catch - if an error occurs, we simply do not get telemetry.
        Write-PSFMessage -Message ('Error sending telemetry: {0}' -f $_.Exception)
    }

    Initialize-LabWindowsActivation -ErrorAction SilentlyContinue

    if (-not $NoValidation -and ($performAll -or $PostDeploymentTests))
    {
        if ((Get-Module -ListAvailable -Name Pester -ErrorAction SilentlyContinue).Version -ge [version]'5.0')
        {
            if ($m = Get-Module -Name Pester | Where-Object Version -lt ([version]'5.0'))
            {
                Write-PSFMessage "The loaded version of Pester $($m.Version) is not compatible with AutomatedLab. Unloading it." -Level Verbose
                $m | Remove-Module
            }
            
            Write-ScreenInfo -Type Verbose -Message "Testing deployment with Pester"
            $result = Invoke-LabPester -Lab (Get-Lab) -Show Normal -PassThru
            if ($result.Result -eq 'Failed')
            {
                Write-ScreenInfo -Type Error -Message "Lab deployment seems to have failed. The following tests were not passed:"
            }

            foreach ($fail in $result.Failed)
            {
                Write-ScreenInfo -Type Error -Message "$($fail.Name)"
            }
        }
        else
        {
            Write-Warning "Cannot run post-deployment Pester test as there is no Pester version 5.0+ installed. Please run 'Install-Module -Name Pester -Force' if you want the post-deployment script to work. You can start the post-deployment tests separately with the command 'Install-Lab -PostDeploymentTests'"
        }
    }

    Send-ALNotification -Activity 'Lab finished' -Message 'Lab deployment successfully finished.' -Provider (Get-LabConfigurationItem -Name Notifications.SubscribedProviders)

    Write-LogFunctionExit
}
