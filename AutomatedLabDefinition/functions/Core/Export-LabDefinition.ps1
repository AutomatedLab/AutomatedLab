function Export-LabDefinition
{
    [CmdletBinding()]
    param (
        [switch]
        $Force,

        [switch]
        $ExportDefaultUnattendedXml = $true,

        [switch]
        $Silent
    )

    Write-LogFunctionEntry

    if (Get-LabMachineDefinition | Where-Object HostType -eq 'HyperV')
    {
        $osesCount = (Get-LabAvailableOperatingSystem -NoDisplay).Count
    }

    #Automatic DNS configuration in Azure if no DNS server is specified and an AD is being deployed
    foreach ($network in (Get-LabVirtualNetworkDefinition | Where HostType -eq Azure))
    {
        $rootDCs = Get-LabMachineDefinition -Role RootDC | Where-Object Network -eq $network
        $dnsServerIP = $rootDCs.IpV4Address

        if (-not $network.DnsServers -and $dnsServerIP)
        {
            $network.DnsServers = $dnsServerIP

            if (-not $Silent)
            {
                Write-ScreenInfo -Message "No DNS server was defined for Azure virtual network while AD is being deployed. Setting DNS server to IP address of '$($rootDCs -join ',')'" -Type Warning
            }
        }
    }

    #Automatic DNS (client) configuration of machines
    $firstRootDc = Get-LabMachineDefinition -Role RootDC | Select-Object -First 1
    $firstRouter = Get-LabMachineDefinition -Role Routing | Select-Object -First 1
    $firstRouterExternalSwitch = $firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

    if ($firstRootDc -or $firstRouter)
    {
        foreach ($machine in (Get-LabMachineDefinition))
        {
            if ($firstRouter)
            {
                $mappingNetworks = Compare-Object -ReferenceObject $firstRouter.NetworkAdapters.VirtualSwitch.Name `
                    -DifferenceObject $machine.NetworkAdapters.VirtualSwitch.Name -ExcludeDifferent -IncludeEqual
            }

            foreach ($networkAdapter in $machine.NetworkAdapters)
            {
                if ($networkAdapter.IPv4DnsServers -contains '0.0.0.0')
                {
                    if (-not $machine.IsDomainJoined) #machine is not domain joined, the 1st network adapter's IP of the 1st root DC is used as DNS server
                    {
                        if ($firstRootDc)
                        {
                            $networkAdapter.IPv4DnsServers = $firstRootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                        }
                        elseif ($firstRouter)
                        {
                            if ($networkAdapter.VirtualSwitch.Name -in $mappingNetworks.InputObject)
                            {
                                $networkAdapter.IPv4DnsServers = ($firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $networkAdapter.VirtualSwitch.Name }).Ipv4Address.IpAddress
                            }
                        }

                    }
                    elseif ($machine.Roles.Name -contains 'RootDC') #if the machine is RootDC, its 1st network adapter's IP is used for DNS
                    {
                        $networkAdapter.IPv4DnsServers = $machine.NetworkAdapters[0].Ipv4Address[0].IpAddress
                    }
                    elseif ($machine.Roles.Name -contains 'FirstChildDC') #if it is a FirstChildDc, the 1st network adapter's IP of the corresponsing RootDC is used
                    {
                        $firstChildDcRole = $machine.Roles | Where-Object Name -eq 'FirstChildDC'
                        $roleParentDomain = $firstChildDcRole.Properties.ParentDomain
                        $rootDc = Get-LabMachineDefinition -Role RootDC | Where-Object DomainName -eq $roleParentDomain

                        $networkAdapter.IPv4DnsServers = $machine.NetworkAdapters[0].Ipv4Address[0].IpAddress, $rootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                    }
                    elseif ($machine.Roles.Name -contains 'DC')
                    {
                        $parentDc = Get-LabMachineDefinition -Role RootDC,FirstChildDc | Where-Object DomainName -eq $machine.DomainName | Select-Object -First 1

                        $networkAdapter.IPv4DnsServers = $machine.NetworkAdapters[0].Ipv4Address[0].IpAddress, $parentDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                    }
                    else #machine is domain joined and not a RootDC or FirstChildDC
                    {
                        Write-PSFMessage "Looking for a root DC in the machine's domain '$($machine.DomainName)'"
                        $rootDc = Get-LabMachineDefinition -Role RootDC | Where-Object DomainName -eq $machine.DomainName
                        if ($rootDc)
                        {
                            Write-PSFMessage "RootDC found, using the IP address of '$rootDc' for DNS: "
                            $networkAdapter.IPv4DnsServers = $rootDc.NetworkAdapters[0].Ipv4Address[0].IpAddress
                        }
                        else
                        {
                            Write-PSFMessage "No RootDC found, looking for FirstChildDC in the machine's domain"
                            $firstChildDC = Get-LabMachineDefinition -Role FirstChildDC | Where-Object DomainName -eq $machine.DomainName

                            if ($firstChildDC)
                            {
                                $networkAdapter.IPv4DnsServers = $firstChildDC.NetworkAdapters[0].Ipv4Address[0].IpAddress
                            }
                            else
                            {
                                Write-ScreenInfo "Automatic assignment of DNS server did not work for machine '$machine'. No domain controller could be found for domain '$($machine.DomainName)'" -Type Warning
                            }
                        }
                    }
                }

                #if there is a router in the network and no gateways defined, we try to set the gateway automatically. This does not
                #apply to network adapters that have a gateway manually configured or set to DHCP, any network adapter on a router,
                #or if there is there wasn't found an external network adapter on the router ($firstRouterExternalSwitch)
                if ($networkAdapter.Ipv4Gateway.Count -eq 0 -and
                    $firstRouterExternalSwitch -and
                    $machine.Roles.Name -notcontains 'Routing' -and
                    -not $networkAdapter.UseDhcp
                )
                {
                    if ($networkAdapter.VirtualSwitch.Name -in $mappingNetworks.InputObject)
                    {
                        $networkAdapter.Ipv4Gateway.Add(($firstRouter.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $networkAdapter.VirtualSwitch.Name } | Select-Object -First 1).Ipv4Address.IpAddress)
                    }
                }
            }
        }
    }

    if (Get-LabMachineDefinition | Where-Object HostType -eq HyperV)
    {
        $hypervMachines = Get-LabMachineDefinition | Where-Object { $_.HostType -eq 'HyperV' -and -not $_.SkipDeployment }
        $hypervUsedOperatingSystems = Get-LabAvailableOperatingSystem -NoDisplay | Where-Object OperatingSystemImageName -in $hypervMachines.OperatingSystem.OperatingSystemName

        $spaceNeededBaseDisks = ($hypervUsedOperatingSystems | Measure-Object -Property Size -Sum).Sum
        $spaceBaseDisksAlreadyClaimed = ($hypervUsedOperatingSystems | Measure-Object -Property size -Sum).Sum
        $spaceNeededData = ($hypervMachines | Where-Object { -not (Get-LWHypervVM -Name $_.ResourceName -ErrorAction SilentlyContinue) }).Count * 2GB

        $spaceNeeded = $spaceNeededBaseDisks + $spaceNeededData - $spaceBaseDisksAlreadyClaimed

        Write-PSFMessage -Message "Space needed by HyperV base disks:                     $([int]($spaceNeededBaseDisks / 1GB))"
        Write-PSFMessage -Message "Space needed by HyperV base disks but already claimed: $([int]($spaceBaseDisksAlreadyClaimed / 1GB * -1))"
        Write-PSFMessage -Message "Space estimated for HyperV data:                       $([int]($spaceNeededData / 1GB))"
        if (-not $Silent)
        {
            Write-ScreenInfo -Message "Estimated (additional) local drive space needed for all machines: $([System.Math]::Round(($spaceNeeded / 1GB),2)) GB" -Type Info
        }

        $labTargetPath = (Get-LabDefinition).Target.Path
        if ($labTargetPath)
        {
            if (-not (Test-Path -Path $labTargetPath))
            {
                try
                {
                    Write-PSFMessage "Creating new folder '$labTargetPath'"
                    New-Item -ItemType Directory -Path $labTargetPath -ErrorAction Stop | Out-Null
                }
                catch
                {
                    Write-Error -Message "Could not create folder '$labTargetPath'. Please make sure that the folder is accessibe and you have permission to write."
                    return
                }
            }

            Write-PSFMessage "Calling 'Get-LabFreeDiskSpace' targeting path '$labTargetPath'"
            $freeSpace = (Get-LabFreeDiskSpace -Path $labTargetPath).FreeBytesAvailable
            Write-PSFMessage "Free disk space is '$([Math]::Round($freeSpace / 1GB, 2))GB'"
            if ($freeSpace -lt $spaceNeeded)
            {
                throw "VmPath parameter is specified for the lab and contains: '$labTargetPath'. However, estimated needed space be $([int]($spaceNeeded / 1GB))GB but drive has only $([System.Math]::Round($freeSpace / 1GB)) GB of free space"
            }
        }
        else
        {
            Set-LabLocalVirtualMachineDiskAuto
            $labTargetPath = (Get-LabDefinition).Target.Path
            if (-not $labTargetPath)
            {
                Throw 'No local drive found matching requirements for free space'
            }
        }

        if (-not $Silent)
        {
            Write-ScreenInfo -Message "Location of Hyper-V machines will be '$labTargetPath'"
        }
    }


    if (-not $lab.LabFilePath)
    {
        $lab.LabFilePath = Join-Path -Path $script:labPath -ChildPath (Get-LabConfigurationItem LabFileName)
        $script:lab | Add-Member -Name Path -MemberType NoteProperty -Value $labFilePath -Force
    }

    if (-not (Test-Path $script:labPath))
    {
        New-Item -Path $script:labPath -ItemType Directory | Out-Null
    }

    if (Test-Path -Path $lab.LabFilePath)
    {
        if ($Force)
        {
            Remove-Item -Path $lab.LabFilePath
        }
        else
        {
            Write-Error 'The file does already exist' -TargetObject $lab.LabFilePath
            return
        }
    }

    try
    {
        $script:lab.Export($lab.LabFilePath)
    }
    catch
    {
        throw $_
    }

    $machineFilePath = $script:lab.MachineDefinitionFiles[0].Path
    $diskFilePath = $script:lab.DiskDefinitionFiles[0].Path

    if (Test-Path -Path $machineFilePath)
    {
        if ($Force)
        {
            Remove-Item -Path $machineFilePath
        }
        else
        {
            Write-Error 'The file does already exist' -TargetObject $machineFilePath
            return
        }
    }

    $script:machines.Export($machineFilePath)
    $script:disks.Export($diskFilePath)

    if ($ExportDefaultUnattendedXml)
    {
        if ($script:machines.Count -eq 0)
        {
            Write-ScreenInfo 'There are no machines defined, nothing to export' -Type Warning
        }
        else
        {
            if ($Script:machines.OperatingSystem | Where-Object Version -lt '6.2')
            {
                $unattendedXmlDefaultContent2008 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2008.xml) -Encoding unicode
            }
            if ($Script:machines.OperatingSystem | Where-Object Version -ge '6.2')
            {
                $unattendedXmlDefaultContent2012 | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath Unattended2012.xml) -Encoding unicode
            }
            if ($Script:machines | Where-Object {$_.LinuxType -eq 'RedHat' -and $_.OperatingSystem.Version -ge 9.0})
            {
                $kickstartContent.Replace('install','').Trim() | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath ks_default.cfg) -Encoding unicode
                $kickstartContent.Replace(' --non-interactive','') | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath ks_defaultLegacy.cfg) -Encoding unicode                
            }
            elseif ($Script:machines | Where-Object LinuxType -eq 'RedHat')
            {
                $kickstartContent | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath ks_default.cfg) -Encoding unicode
                $kickstartContent.Replace(' --non-interactive','') | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath ks_defaultLegacy.cfg) -Encoding unicode                
            }
            if ($Script:machines | Where-Object LinuxType -eq 'Suse')
            {
                $autoyastContent | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath autoinst_default.xml) -Encoding unicode
            }
            if ($Script:machines | Where-Object LinuxType -eq 'Ubuntu')
            {
                $cloudInitContent | Out-File -FilePath (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath cloudinit_default.yml) -Encoding unicode
            }
        }
    }

    $Global:labExported = $true

    Write-LogFunctionExit
}
