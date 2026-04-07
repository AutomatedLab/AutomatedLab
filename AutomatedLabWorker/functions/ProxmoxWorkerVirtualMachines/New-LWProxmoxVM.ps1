function New-LWProxmoxVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'Not relevant on Linux')]
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    if ($Machine.SkipDeployment)
    {
        return
    }

    Write-LogFunctionEntry

    $script:lab = Get-Lab

    $proxmoxNodes = Get-LWProxmoxNode
    $proxmoxVMs = Get-LWProxmoxVM -Node $proxmoxNodes -IncludeTemplates

    if ($vm = $proxmoxVMs | Where-Object { $_.Name -eq $Machine.ResourceName })
    {
        $vm = Get-LWProxmoxVM -ComputerName $Machine.ResourceName -Node $vm.node -NoCache -NoError
        if ($null -ne $vm)
        {
            Write-ProgressIndicatorEnd
            Write-ScreenInfo -Message "The machine '$Machine' does already exist" -Type Warning
            return $false
        }
    }

    $template = $proxmoxNodes | Get-LWProxmoxVmTemplate -OperatingSystem $Machine.OperatingSystem
    if (-not $template)
    {
        Write-Error "No template found for operating system '$($Machine.OperatingSystem)'. Cannot create VM '$($Machine.ResourceName)'." -ErrorAction Stop
    }
    if ($template.Count -gt 1)
    {
        Write-Error "Multiple templates found for operating system '$($Machine.OperatingSystem)'. Cannot create VM '$($Machine.ResourceName)'. Please ensure only one template exists per operating system." -ErrorAction Stop
    }

    Write-PSFMessage "Using template '$($template.Name)' (VMID: $($template.VMID)) on Proxmox node '$($template.node)' to create VM '$($Machine.ResourceName)'."
    Write-ScreenInfo -Message "Creating Proxmox machine '$($Machine.ResourceName)' from template '$($template.Name)' (VMID $($template.VMID))"

    $storage = Invoke-LWProxmoxCallWithRetry -ActivityName "Retrieve storage for VM '$($Machine.ResourceName)'" -ScriptBlock { Get-PveStorage }
    if ($storage.StatusCode -ne 200)
    {
        Write-Error "Failed to retrieve storage information from Proxmox cluster: $($storage.ReasonPhrase)"
        return
    }

    $storage = $storage.Response.data | Where-Object { $_.type -in @('dir', 'lvm', 'zfspool', 'btrfs', 'nfs', 'cephfs', 'rbd') }

    if ($Machine.ProxmoxProperties.Storage)
    {
        if ($storage.storage -notcontains $Machine.ProxmoxProperties.Storage)
        {
            Write-Error "The specified storage '$($Machine.ProxmoxProperties.Storage)' does not exist in the Proxmox cluster."
            return
        }
    }

    # Every file in that folder will be copied to the VM
    $vhdVolume = "C:\ProgramData\AutomatedLab\Labs\$($lab.Name)\Proxmox\VHD\$($Machine.ResourceName)"
    mkdir -Path $vhdVolume -Force | Out-Null

    $nextVmId = (Get-LWProxmoxVM -IncludeTemplates -NoCache | Sort-Object -Property vmid -Descending | Select-Object -First 1).vmid + 1

    $param = @{
        Node        = $template.node
        Name        = $Machine.ResourceName
        Description = "Lab '$($lab.Name)'. Created by AutomatedLab"
        Vmid        = $template.vmid
        Newid       = $nextVmId
    }

    if ($Machine.ProxmoxProperties.TargetNode)
    {
        $param.Target = $Machine.ProxmoxProperties.TargetNode
    }
    if ($Machine.ProxmoxProperties.FullClone)
    {
        $param.Full = $true
    }
    if ($Machine.ProxmoxProperties.Pool)
    {
        $param.Pool = $Machine.ProxmoxProperties.Pool
    }
    if ($Machine.ProxmoxProperties.Storage)
    {
        $param.Storage = $Machine.ProxmoxProperties.Storage
    }

    #TODO: Not sure yet, if this test makes sense
    #if (-not $globa:proxmoxPool -and -not $global:proxmoxStorage)
    #{
    #    Write-Error 'Neither the Proxmox pool nor the storage have been specified. Using the storage of the template.' -ErrorAction Stop
    #}

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Clone VM '$($Machine.ResourceName)'" -ScriptBlock { New-PveNodesQemuClone @param }
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Failed to create VM '$($Machine.ResourceName)': $($result.ReasonPhrase)"
        return
    }
    Write-Verbose "Waiting for VM '$($Machine.ResourceName)' to be created..."
    $values = @{
        status = 'stopped'
    }
    $result = Wait-LWProxmoxTasksStatus -Node $template.node -Upid $result.Response.data -DesiredValues $values -TimeoutInSeconds 600
    if ($result -ne 'OK')
    {
        Write-Error "Failed to create VM '$($Machine.ResourceName)': $($result.Message)"
        return
    }
    Write-Verbose 'done.'

    # Persist the assigned VMID in the lab definition so Get-LabVM can return it
    $proxProps = $Machine.ProxmoxProperties
    $proxProps['VmId'] = $nextVmId.ToString()
    $Machine.ProxmoxProperties = $proxProps
    Write-PSFMessage "Stored VmId '$nextVmId' in ProxmoxProperties for VM '$($Machine.ResourceName)'"
    Export-Lab

    Write-PSFMessage "`tSettings RAM, start and stop actions"

    if ($Machine.MaxMemory)
    {
        Write-PSFMessage "`tThe setting 'MaxMemory' is not supported on Proxmox VMs and will be ignored."
    }
    if ($Machine.MinMemory)
    {
        Write-PSFMessage "`tThe setting 'MinMemory' is not supported on Proxmox VMs and will be ignored."
    }

    $param = @{
        Vmid        = $nextVmId
        Node        = $Machine.ProxmoxProperties.TargetNode
        Cores       = $Machine.Processors
        Memory      = $Machine.Memory / 1MB
        Tags        = "AutomatedLab, $($lab.Name), $((Get-Date).ToString('yyMMdd_HHmmss'))"
        Description = "Created by AutomatedLab on $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
        LocalTime   = 1
        Agent      = 'enabled=true,fstrim_cloned_disks=true,type=virtio'
        Cpu = Get-LabConfigurationItem -Name DefaultCpuType
    }

    if ($Machine.ProxmoxProperties.CpuType)
    {
        $param.Cpu = $Machine.ProxmoxProperties.CpuType
    }

    $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Configure VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig @param }
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Failed to configure VM '$($Machine.ResourceName)': $($result.ReasonPhrase)"
        return
    }

    #Remove CD/DVD Drives
    $config = Get-LWProxmoxVMConfig -ComputerName $Machine.ResourceName -Node $Machine.ProxmoxProperties.TargetNode -NoCache
    if (-not $config)
    {
        Write-Error "Could not retrieve VM config for VM '$($Machine.ResourceName)' on node $($Machine.ProxmoxProperties.TargetNode)."
        return
    }
    $existingDrives = $config | Get-Member | Where-Object Name -Match 'ide\d{1,3}'
    foreach ($existingDrive in $existingDrives)
    {
        $null = Invoke-LWProxmoxCallWithRetry -ActivityName "Remove drive '$($existingDrive.Name)' from VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig -Vmid $nextVmId -Node $Machine.ProxmoxProperties.TargetNode -Delete $existingDrive.Name }
    }

    # --------------------------- Disk Configuration ------------------------------------------
    # Setting cache and Async IO options for the main disk (scsi0)
    if (-not ($config.scsi0 -match 'aio=(?<aioValue>native|threads|io_uring)'))
    {
        Write-PSFMessage "Adding 'aio=threads' to scsi0 configuration"
        $config.scsi0 += ',aio=threads'
    }
    else
    {
        Write-PSFMessage "Updating 'aio' from '$($matches.aioValue)' to 'threads' in scsi0 configuration"
        $config.scsi0 = $config.scsi0 -replace 'aio=(native|threads|io_uring)', 'aio=threads'
    }

    if (-not ($config.scsi0 -match 'cache=(?<cacheValue>none|writeback|writethrough|directsync|unsafe)'))
    {
        Write-PSFMessage "Adding 'cache=writeback' to scsi0 configuration"
        $config.scsi0 += ',cache=writeback'
    }
    else
    {
        Write-PSFMessage "Updating 'cache' from '$($matches.cacheValue)' to 'writeback' in scsi0 configuration"
        $config.scsi0 = $config.scsi0 -replace 'cache=(none|writeback|writethrough|directsync|unsafe)', 'cache=writeback'
    }
    $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Configure scsi0 on VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig -Vmid $nextVmId -Node $Machine.ProxmoxProperties.TargetNode -ScsiN @{ 0 = $config.scsi0 } }
    if ($result.StatusCode -ne 200)
    {
        Write-Error "Failed to configure scsi0 on VM '$($Machine.ResourceName)': $($result.ReasonPhrase)"
    }

    #Get VMs storage name
    if (-not ($config.efidisk0 -match '(?<StorageName>.+):'))
    {
        write-Error "Could not determine storage name for efi disk on VM '$($Machine.ResourceName)'."
        return
    }
    $storageName = $matches.StorageName

    # Add the additional hard disks
    $i = 1
    foreach ($disk in $Machine.Disks)
    {
        $diskHashTable = @{
            $i = "$($storageName):$($disk.DiskSize),aio=threads,cache=writeback"
        }
        $result = Invoke-LWProxmoxCallWithRetry -ActivityName "Configure disk $i on VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig -Vmid $nextVmId -Node $Machine.ProxmoxProperties.TargetNode -ScsiN $diskHashTable }
        if ($result.StatusCode -ne 200)
        {
            Write-Error "Failed to configure disk $i on VM '$($Machine.ResourceName)': $($result.ReasonPhrase)"
        }
        $disk.Lun = $i
        $i++
    }
    $Machine.Disks | Export-Clixml -Path (Join-Path -Path $vhdVolume -ChildPath Disks.xml)

    # ------------------------------------------------------------------------------------------

    if ($PSDefaultParameterValues.ContainsKey('*:IsKickstart'))
    {
        $PSDefaultParameterValues.Remove('*:IsKickstart')
    }
    if ($PSDefaultParameterValues.ContainsKey('*:IsAutoYast'))
    {
        $PSDefaultParameterValues.Remove('*:IsAutoYast')
    }
    if ($PSDefaultParameterValues.ContainsKey('*:IsCloudInit'))
    {
        $PSDefaultParameterValues.Remove('*:IsCloudInit')
    }

    if ($Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'RedHat')
    {
        $PSDefaultParameterValues['*:IsKickstart'] = $true
    }
    if ($Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'Suse')
    {
        $PSDefaultParameterValues['*:IsAutoYast'] = $true
    }
    if ($Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'Ubuntu')
    {
        $PSDefaultParameterValues['*:IsCloudInit'] = $true
    }

    Write-PSFMessage "Creating machine with the name '$($Machine.ResourceName)' in the path '$VmPath'"

    #region Unattend XML settings
    if (-not $Machine.ProductKey)
    {
        if ($Machine.OperatingSystem.ProductKey)
        {
            $Machine.ProductKey = $Machine.OperatingSystem.ProductKey
        }
        else
        {
            $Machine.ProductKey = Get-LWProductKey -OSName $Machine.OperatingSystem.OperatingSystemName
        }
    }

    $unattendContent = $Machine.UnattendedXmlContent
    if ($Machine.LinuxType -eq 'Suse' -and $Machine.OperatingSystem.OperatingSystemName -match 'Leap')
    {
        $unattendContent = $unattendContent -replace 'SUSEVERSION', "$($Machine.OperatingSystem.Version.Major).$($Machine.OperatingSystem.Version.Minor)"
    }

    Import-UnattendedContent -Content $unattendContent

    # Ensure package selection works
    if ($Machine.LinuxType -eq 'Suse' -and $Machine.OperatingSystem.OperatingSystemName -match 'Tumbleweed')
    {
        $nsm = [System.Xml.XmlNamespaceManager]::new((Get-UnattendedContent).NameTable)
        $nsm.AddNamespace('un', 'http://www.suse.com/1.0/yast2ns')
        $nsm.AddNamespace('config', 'http://www.suse.com/1.0/configns' )
        $addOnNode = (Get-UnattendedContent).SelectSingleNode('/un:profile/un:add-on/un:add_on_others', $nsm)
        $addOnNode.RemoveAll()

        # Restore attribute after clearing the node
        $listAttr = (Get-UnattendedContent).CreateAttribute('t')
        $listAttr.InnerText = 'list'
        $null = $addOnNode.Attributes.Append($listAttr)

        $listNodeUpdate = (Get-UnattendedContent).CreateElement('listentry', $nsm.LookupNamespace('un'))
        $mapAttr = (Get-UnattendedContent).CreateAttribute('t')
        $mapAttr.InnerText = 'map'
        $aliasNode = (Get-UnattendedContent).CreateElement('alias', $nsm.LookupNamespace('un'))
        $aliasNode.InnerText = 'repo-update'
        $mediaUrlNode = (Get-UnattendedContent).CreateElement('media_url', $nsm.LookupNamespace('un'))
        $mediaUrlNode.InnerText = 'http://download.opensuse.org/update/tumbleweed/'
        $nameNode = (Get-UnattendedContent).CreateElement('name', $nsm.LookupNamespace('un'))
        $nameNode.InnerText = 'Update'
        $priorityNode = (Get-UnattendedContent).CreateElement('priority', $nsm.LookupNamespace('un'))
        $priorityNode.InnerText = '1'
        $null = $listNodeUpdate.AppendChild($aliasNode)
        $null = $listNodeUpdate.AppendChild($mediaUrlNode)
        $null = $listNodeUpdate.AppendChild($nameNode)
        $null = $listNodeUpdate.AppendChild($priorityNode)
        $null = $listNodeUpdate.Attributes.Append($mapAttr)
        $null = $addOnNode.AppendChild($listNodeUpdate)


        $listNodeNonOss = (Get-UnattendedContent).CreateElement('listentry', $nsm.LookupNamespace('un'))
        $mapAttr = (Get-UnattendedContent).CreateAttribute('t')
        $mapAttr.InnerText = 'map'
        $aliasNode = (Get-UnattendedContent).CreateElement('alias', $nsm.LookupNamespace('un'))
        $aliasNode.InnerText = 'repo-update'
        $mediaUrlNode = (Get-UnattendedContent).CreateElement('media_url', $nsm.LookupNamespace('un'))
        $mediaUrlNode.InnerText = 'http://download.opensuse.org/tumbleweed/repo/non-oss/'
        $nameNode = (Get-UnattendedContent).CreateElement('name', $nsm.LookupNamespace('un'))
        $nameNode.InnerText = 'Update'
        $priorityNode = (Get-UnattendedContent).CreateElement('priority', $nsm.LookupNamespace('un'))
        $priorityNode.InnerText = '2'
        $null = $listNodeNonOss.AppendChild($aliasNode)
        $null = $listNodeNonOss.AppendChild($mediaUrlNode)
        $null = $listNodeNonOss.AppendChild($nameNode)
        $null = $listNodeNonOss.AppendChild($priorityNode)
        $null = $listNodeNonOss.Attributes.Append($mapAttr)
        $null = $addOnNode.AppendChild($listNodeNonOss)
    }
    #endregion

    #---------------------------------------------------------------------------

    #region network adapter settings
    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.NetworkAdapter
    $adapters = New-Object $type
    $Machine.NetworkAdapters | ForEach-Object { $adapters.Add($_) }

    # remove existing network adapters, later the defined adapters will be added again
    $config = Get-LWProxmoxVMConfig -ComputerName $Machine.ResourceName -Node $Machine.ProxmoxProperties.TargetNode -NoCache
    if (-not $config)
    {
        Write-Error "Could not retrieve VM config for VM '$($Machine.ResourceName)' on node $($Machine.ProxmoxProperties.TargetNode)."
        return
    }
    $existingNetAdapters = $config | Get-Member | Where-Object Name -Match 'net\d{1,3}'

    foreach ($existingNetAdapter in $existingNetAdapters)
    {
        $null = Invoke-LWProxmoxCallWithRetry -ActivityName "Remove net adapter '$($existingNetAdapter.Name)' from VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig -Vmid $nextVmId -Node $Machine.ProxmoxProperties.TargetNode -Delete $existingNetAdapter.Name }
    }

    $existingMacAddresses = @(Get-LWProxmoxUsedMacAddresses -NoSeparator)
    $macAddressPrefix = Get-LabConfigurationItem -Name ProxmoxMacAddressPrefix
    $macAddressPrefix = $macAddressPrefix -replace '(.{2})(?=.)', '$1:'
    $macAddressPrefix += ':00:00:00'

    #---------------------------------------------------------------------------

    if ($Machine.IsDomainJoined)
    {
        #move the adapter that connects the machine to the domain to the top
        $dc = Get-LabVM -Role RootDC, FirstChildDC | Where-Object { $_.DomainName -eq $Machine.DomainName }

        if ($dc)
        {
            #the first adapter that has an IP address in the same IP range as the RootDC or FirstChildDC in the same domain will be used on top of
            #the network ordering
            $domainAdapter = $adapters | Where-Object { $_.Ipv4Address[0] } |
                Where-Object { [AutomatedLab.IPNetwork]::Contains($_.Ipv4Address[0], $dc.IpAddress[0]) } |
                    Select-Object -First 1

            if ($domainAdapter)
            {
                $adapters.Remove($domainAdapter)
                $adapters.Insert(0, $domainAdapter)
            }
        }
    }

    $adapterCount = 0
    foreach ($adapter in $adapters)
    {
        $ipSettings = @{}
        $openSuseLinuxRcNetwork = [System.Text.StringBuilder]::new()
        $null = $openSuseLinuxRcNetwork.Append("ifcfg=`"eth$($adapterCount)`"=")

        $mac = New-MacAddress -MacAddressPrefix $macAddressPrefix -ExistingMacAddresses $existingMacAddresses
        $mac = $mac -replace '[:\-]', ''
        $existingMacAddresses += $mac

        if (-not $adapter.MacAddress)
        {
            $adapter.MacAddress = $mac
        }

        #$ipSettings.Add('MacAddress', $adapter.MacAddress)
        $macWithDash = '{0}-{1}-{2}-{3}-{4}-{5}' -f (Get-StringSection -SectionSize 2 -String $adapter.MacAddress)

        $ipSettings.Add('InterfaceName', $macWithDash)
        $ipSettings.Add('IpAddresses', @())
        if ($adapter.Ipv4Address.Count -ge 1)
        {
            foreach ($ipv4Address in $adapter.Ipv4Address)
            {
                $ipSettings.IpAddresses += "$($ipv4Address.IpAddress)/$($ipv4Address.Cidr)"
            }
        }
        if ($adapter.Ipv6Address.Count -ge 1)
        {
            foreach ($ipv6Address in $adapter.Ipv6Address)
            {
                $ipSettings.IpAddresses += "$($ipv6Address.IpAddress)/$($ipv6Address.Cidr)"
            }
        }

        $ipSettings.Add('Gateways', ($adapter.Ipv4Gateway + $adapter.Ipv6Gateway))
        $ipSettings.Add('DNSServers', ($adapter.Ipv4DnsServers + $adapter.Ipv6DnsServers))

        $null = $openSuseLinuxRcNetwork.Append($ipSettings.IpAddresses -join ' ')
        $null = $openSuseLinuxRcNetwork.Append(' ')
        $null = $openSuseLinuxRcNetwork.Append($ipSettings.Gateways -join ' ')
        $null = $openSuseLinuxRcNetwork.Append(' ')
        $null = $openSuseLinuxRcNetwork.Append($ipSettings.DNSServers -join ' ')

        if (-not $Machine.IsDomainJoined -and (-not $adapter.ConnectionSpecificDNSSuffix))
        {
            $rootDomainName = Get-LabVM -Role RootDC | Select-Object -First 1 | Select-Object -ExpandProperty DomainName
            $ipSettings.Add('DnsDomain', $rootDomainName)
            $null = $openSuseLinuxRcNetwork.Append(" $rootDomainName")
        }

        if ($adapter.ConnectionSpecificDNSSuffix)
        {
            $ipSettings.Add('DnsDomain', $adapter.ConnectionSpecificDNSSuffix)
            $null = $openSuseLinuxRcNetwork.Append(" $($adapter.ConnectionSpecificDNSSuffix)")
        }

        $ipSettings.Add('UseDomainNameDevolution', (([string]($adapter.AppendParentSuffixes)) = 'true'))
        if ($adapter.AppendDNSSuffixes)
        {
            $ipSettings.Add('DNSSuffixSearchOrder', $adapter.AppendDNSSuffixes -join ',')
            $null = $openSuseLinuxRcNetwork.Append(" $($adapter.AppendDNSSuffixes -join ' ')")
        }

        $ipSettings.Add('EnableAdapterDomainNameRegistration', ([string]($adapter.DnsSuffixInDnsRegistration)).ToLower())
        $ipSettings.Add('DisableDynamicUpdate', ([string](-not $adapter.RegisterInDNS)).ToLower())

        if ($machine.OperatingSystemType -eq 'Linux' -and $machine.LinuxType -eq 'RedHat')
        {
            $ipSettings.Add('IsKickstart', $true)
        }
        if ($machine.OperatingSystemType -eq 'Linux' -and $machine.LinuxType -eq 'Suse')
        {
            $ipSettings.Add('IsAutoYast', $true)
        }
        if ($machine.OperatingSystemType -eq 'Linux' -and $machine.LinuxType -eq 'Ubuntu')
        {
            $ipSettings.Add('IsCloudInit', $true)
        }

        switch ($Adapter.NetbiosOptions)
        {
            'Default'
            {
                $ipSettings.Add('NetBIOSOptions', '0')
            }
            'Enabled'
            {
                $ipSettings.Add('NetBIOSOptions', '1')
            }
            'Disabled'
            {
                $ipSettings.Add('NetBIOSOptions', '2')
            }
        }

        Add-UnattendedNetworkAdapter @ipSettings
        $adapterCount++
    }

    $Machine.NetworkAdapters = $adapters
    Export-Lab

    # Add the network adapters to the Proxmox VM
    $i = 0
    foreach ($networkAdapter in $Machine.NetworkAdapters)
    {
        $netAdapterHashTable = @{
            $i = "model=virtio,macaddr=$($networkAdapter.MacAddress -replace '(.{2})(?!$)', '$1:'),bridge=$($networkAdapter.VirtualSwitch),firewall=1"
        }
        $null = Invoke-LWProxmoxCallWithRetry -ActivityName "Add network adapter $i to VM '$($Machine.ResourceName)'" -ScriptBlock { Set-PveNodesQemuConfig -Vmid $nextVmId -Node $Machine.ProxmoxProperties.TargetNode -NetN $netAdapterHashTable }
        $i++
    }

    if ($Machine.OperatingSystemType -eq 'Windows')
    {
        Add-UnattendedRenameNetworkAdapters
    }
    #endregion network adapter settings

    Set-UnattendedComputerName -ComputerName $Machine.Name
    Set-UnattendedAdministratorName -Name $Machine.InstallationUser.UserName
    Set-UnattendedAdministratorPassword -Password $Machine.InstallationUser.Password

    if ($Machine.ProductKey)
    {
        Set-UnattendedProductKey -ProductKey $Machine.ProductKey
    }

    if ($Machine.UserLocale)
    {
        Set-UnattendedUserLocale -UserLocale $Machine.UserLocale
    }

    #if the time zone is specified we use it, otherwise we take the timezone from the host machine
    if ($Machine.TimeZone)
    {
        Set-UnattendedTimeZone -TimeZone $Machine.TimeZone
    }
    else
    {
        Set-UnattendedTimeZone -TimeZone ([System.TimeZoneInfo]::Local.Id)
    }

    #if domain-joined and not a DC
    if ($Machine.IsDomainJoined -eq $true -and -not ($Machine.Roles.Name -contains 'RootDC' -or $Machine.Roles.Name -contains 'FirstChildDC' -or $Machine.Roles.Name -contains 'DC'))
    {
        Set-UnattendedAutoLogon -DomainName $Machine.DomainName -Username $Machine.InstallationUser.Username -Password $Machine.InstallationUser.Password
    }
    else
    {
        Set-UnattendedAutoLogon -DomainName $Machine.Name -Username $Machine.InstallationUser.Username -Password $Machine.InstallationUser.Password
    }

    $disableWindowsDefender = Get-LabConfigurationItem -Name DisableWindowsDefender
    if (-not $disableWindowsDefender)
    {
        Set-UnattendedAntiMalware -Enabled $false
    }

    $setLocalIntranetSites = Get-LabConfigurationItem -Name SetLocalIntranetSites
    if ($setLocalIntranetSites -ne 'None' -or $null -ne $setLocalIntranetSites)
    {
        if ($setLocalIntranetSites -eq 'All')
        {
            $localIntranetSites = $lab.Domains
        }
        elseif ($setLocalIntranetSites -eq 'Forest' -and $Machine.DomainName)
        {
            $forest = $lab.GetParentDomain($Machine.DomainName)
            $localIntranetSites = $lab.Domains | Where-Object { $lab.GetParentDomain($_) -eq $forest }
        }
        elseif ($setLocalIntranetSites -eq 'Domain' -and $Machine.DomainName)
        {
            $localIntranetSites = $Machine.DomainName
        }

        $localIntranetSites = $localIntranetSites | ForEach-Object {
            "http://$($_)"
            "https://$($_)"
        }

        #removed the call to Set-LocalIntranetSites as setting the local intranet zone in the unattended file does not work due to bugs in Windows
        #Set-LocalIntranetSites -Values $localIntranetSites
    }

    Set-UnattendedFirewallState -State $Machine.EnableWindowsFirewall

    if ($Machine.LinuxType -eq 'Suse')
    {
        try
        {
            $repoContent = (Invoke-RestMethod -Method Get -Uri "https://packages.microsoft.com/config/rhel/$Version/prod.repo" -ErrorAction Stop) -split "`n"
        }
        catch
        {
        }

        $pwshRelease = ((Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -ErrorAction SilentlyContinue).assets | Where-Object Name -Match 'rh\.x86_64\.rpm').browser_download_url
        if (-not $pwshRelease)
        {
            $pwshRelease = 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/powershell-7.5.2-1.rh.x86_64.rpm'
        }

        Add-UnattendedSynchronousCommand -Command "sudo zypper update -y && sudo zypper install -y libicu libopenssl3`nsudo rpm -i --nodeps $pwshRelease`necho `"Subsystem powershell /usr/bin/pwsh -sshs -NoLogo`" >> /etc/ssh/sshd_config`nsystemctl restart sshd`n" -Description 'Install PowerShell'
    }

    if ($Machine.OperatingSystemType -eq 'Linux' -and -not [string]::IsNullOrEmpty($Machine.SshPublicKey))
    {
        $command = @"
mkdir -p /root/.ssh
mkdir -p /home/$($Machine.InstallationUser.UserName)/.ssh
echo "$($Machine.SshPublicKey)" > /root/.ssh/authorized_keys
echo "$($Machine.SshPublicKey)" > /home/$($Machine.InstallationUser.UserName)/.ssh/authorized_keys
chown -R root:root /root/.ssh
chown -R $($Machine.InstallationUser.UserName):$($Machine.InstallationUser.UserName) /home/$($Machine.InstallationUser.UserName)/.ssh
chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys
chmod 700 /home/$($Machine.InstallationUser.UserName)/.ssh && chmod 600 /home/$($Machine.InstallationUser.UserName)/.ssh/authorized_keys
sed -i 's|[#]*GSSAPIAuthentication yes|GSSAPIAuthentication yes|g' /etc/ssh/sshd_config
sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
sed -i 's|[#]*PubkeyAuthentication yes|PubkeyAuthentication yes|g' /etc/ssh/sshd_config
restorecon -R /$($Machine.InstallationUser.UserName)/.ssh/
restorecon -R /root/.ssh/
"@
        Add-UnattendedSynchronousCommand -Command $command -Description 'SSH'
    }

    if ($Machine.Roles.Name -contains 'RootDC' -or
        $Machine.Roles.Name -contains 'FirstChildDC' -or
        $Machine.Roles.Name -contains 'DC')
    {
        #machine will not be added to domain or workgroup
    }
    else
    {
        if (-not [string]::IsNullOrEmpty($Machine.WorkgroupName))
        {
            Set-UnattendedWorkgroup -WorkgroupName $Machine.WorkgroupName
        }

        if (-not [string]::IsNullOrEmpty($Machine.DomainName))
        {
            $domain = $lab.Domains | Where-Object Name -EQ $Machine.DomainName

            $parameters = @{
                DomainName = $Machine.DomainName
                Username   = $domain.Administrator.UserName
                Password   = $domain.Administrator.Password
            }
            if ($Machine.OrganizationalUnit)
            {
                $parameters['OrganizationalUnit'] = $machine.OrganizationalUnit
            }

            Set-UnattendedDomain @parameters

            if ($Machine.OperatingSystemType -eq 'Linux')
            {
                if ($Machine.LinuxType -eq 'Suse')
                {
                    Set-UnattendedPackage -Package sssd, samba
                }

                $sudoParam = @{
                    Command     = "sed -i '/^%wheel.*/a %$($Machine.DomainName.ToUpper())\\\\domain\\ admins ALL=(ALL) NOPASSWD: ALL' /etc/sudoers"
                    Description = 'Enable domain admin as sudoer without password'
                }

                Add-UnattendedSynchronousCommand @sudoParam

                if (-not [string]::IsNullOrEmpty($Machine.SshPublicKey))
                {
                    $command = @"
mkdir -p /home/$($Machine.InstallationUser.UserName.ToLower())@$($Machine.DomainName.ToLower())/.ssh
chown -R "$($Machine.InstallationUser.UserName)@$($Machine.DomainName):domain users@$($Machine.DomainName)" /home/$($Machine.InstallationUser.UserName.ToLower())@$($Machine.DomainName.ToLower())/.ssh
chmod 700 /home/$($Machine.InstallationUser.UserName.ToLower())@$($Machine.DomainName.ToLower())/.ssh && chmod 600 /home/$($Machine.InstallationUser.UserName.ToLower())@$($Machine.DomainName.ToLower())/.ssh/authorized_keys
echo "$($Machine.SshPublicKey)" > /home/$($Machine.InstallationUser.UserName.ToLower())@$($Machine.DomainName.ToLower())/.ssh/authorized_keys
restorecon -R /$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh/
"@
                    Add-UnattendedSynchronousCommand -Command $command -Description 'SSH'
                }
            }
        }
    }

    Write-ProgressIndicator

    #TODO Unlear yet
    <#
    if ($Machine.OperatingSystemType -eq 'Linux')
    {
        if ( $machine.OperatingSystemType -eq 'Linux' -and $machine.LinuxPackageGroup )
        {
            Set-UnattendedPackage -Package $machine.LinuxPackageGroup
        }
        elseif ($machine.LinuxType -eq 'RedHat')
        {
            Set-UnattendedPackage -Package '@^server-product-environment'
        }

        # Copy Unattend-Stuff here
        if ($machine.LinuxType -eq 'RedHat')
        {
            Export-UnattendedFile -Path (Join-Path -Path $drive.RootDirectory -ChildPath ks.cfg) -Version $machine.OperatingSystem.Version.Major
            Copy-Item -Path (Join-Path -Path $drive.RootDirectory -ChildPath ks.cfg) -Destination (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath "ks_$($Machine.Name).cfg")
        }
        elseif ($Machine.LinuxType -eq 'Suse')
        {
            Export-UnattendedFile -Path (Join-Path -Path $drive.RootDirectory -ChildPath autoinst.xml)
            Export-UnattendedFile -Path (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath "autoinst_$($Machine.Name).xml")
            # Mount ISO
            $mountedIso = Mount-DiskImage -ImagePath $Machine.OperatingSystem.IsoPath -PassThru | Get-Volume
            $isoDrive = [System.IO.DriveInfo][string]$mountedIso.DriveLetter
            # Copy data
            Copy-Item -Path "$($isoDrive.RootDirectory.FullName)*" -Destination $drive.RootDirectory.FullName -Recurse -Force -PassThru |
            Where-Object IsReadOnly | Set-ItemProperty -name IsReadOnly -Value $false

            # Unmount ISO
            [void] (Dismount-DiskImage -ImagePath $Machine.OperatingSystem.IsoPath)

            # AutoYast XML file is not picked up properly without modifying bootloader config
            # Change grub and isolinux configuration
            $grubFile = Get-ChildItem -Recurse -Path $drive.RootDirectory.FullName -Filter 'grub.cfg'
            $isolinuxFile = Get-ChildItem -Recurse -Path $drive.RootDirectory.FullName -Filter 'isolinux.cfg'

            ($grubFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 $openSuseLinuxRcNetwork YAST_SKIP_XML_VALIDATION=1 autoyast=device:///autoinst.xml" | Set-Content -Path $grubFile.FullName
            ($isolinuxFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 $openSuseLinuxRcNetwork YAST_SKIP_XML_VALIDATION=1 autoyast=device:///autoinst.xml" | Set-Content -Path $isolinuxFile.FullName
        }
        elseif ($machine.LinuxType -eq 'Ubuntu')
        {
            $null = New-Item -Path $drive.RootDirectory -Name meta-data -Force -Value "instance-id: iid-local01`nlocal-hostname: $($Machine.Name)"
            Export-UnattendedFile -Path (Join-Path -Path $drive.RootDirectory -ChildPath user-data)
            $ubuLease = '{0:d2}.{1:d2}' -f $machine.OperatingSystem.Version.Major,$machine.OperatingSystem.Version.Minor # Microsoft Repo does not use $RELEASE but version number instead.
            (Get-Content -Path (Join-Path -Path $drive.RootDirectory -ChildPath user-data)) -replace 'REPLACERELEASE', $ubuLease | Set-Content (Join-Path -Path $drive.RootDirectory -ChildPath user-data)
            Copy-Item -Path (Join-Path -Path $drive.RootDirectory -ChildPath user-data) -Destination (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath "cloudinit_$($Machine.Name).yml")
        }

        $mountedOsDisk | Dismount-VHD

        if ($PSDefaultParameterValues.ContainsKey('*:IsKickstart')) { $PSDefaultParameterValues.Remove('*:IsKickstart') }
        if ($PSDefaultParameterValues.ContainsKey('*:IsAutoYast')) { $PSDefaultParameterValues.Remove('*:IsAutoYast') }
        if ($PSDefaultParameterValues.ContainsKey('*:CloudInit')) { $PSDefaultParameterValues.Remove('*:CloudInit') }
    }
    else
    {
    #>

    #TODO: The copy job needs to go somewhere else
    <#
    $paths = [Collections.ArrayList]::new()
    $alcommon = Get-Module -Name AutomatedLab.Common
    $null = $paths.Add((Split-Path -Path $alcommon.ModuleBase -Parent))
    $null = foreach ($req in $alCommon.RequiredModules.Name)
    {
        $paths.Add((Split-Path -Path (Get-Module -Name $req -ListAvailable)[0].ModuleBase -Parent))
    }

    Copy-Item -Path $paths -Destination "$($drive.DriveLetter):\Program Files\WindowsPowerShell\Modules" -Recurse
    #>

    #TODO: The DSC job needs to go somewhere else
    <#
    if ($Machine.InitialDscConfigurationMofPath)
    {
        $exportedModules = Get-RequiredModulesFromMOF -Path $Machine.InitialDscConfigurationMofPath
        foreach ($exportedModule in $exportedModules.GetEnumerator())
        {
            $moduleInfo = Get-Module -ListAvailable -Name $exportedModule.Key | Where-Object Version -eq $exportedModule.Value | Select-Object -First 1
            if (-not $moduleInfo)
            {
                Write-ScreenInfo -Type Warning -Message "Unable to find $($exportedModule.Key). Attempting to download from PSGallery"
                Save-Module -Path "$($drive.DriveLetter):\Program Files\WindowsPowerShell\Modules" -Name $exportedModule.Key -RequiredVersion $exportedModule.Value -Repository PSGallery -Force -AllowPrerelease
            }
            else
            {
                $source = Get-ModuleDependency -Module $moduleInfo | Sort-Object -Unique | ForEach-Object {
                    if ((Get-Item $_).BaseName -match '\d{1,4}\.\d{1,4}\.\d{1,4}' -and $Machine.OperatingSystem.Version -ge 10.0)
                    {
                        #parent folder contains a specific version. In order to copy the module right, the parent of this parent is required
                        Split-Path -Path $_ -Parent
                    }
                    else
                    {
                        $_
                    }
                }

                Copy-Item -Recurse -Path $source -Destination "$($drive.DriveLetter):\Program Files\WindowsPowerShell\Modules"
            }
        }
        Copy-Item -Path $Machine.InitialDscConfigurationMofPath -Destination "$($drive.DriveLetter):\Windows\System32\configuration\pending.mof"
    }

    if ($Machine.InitialDscLcmConfigurationMofPath)
    {
        Copy-Item -Path $Machine.InitialDscLcmConfigurationMofPath -Destination "$($drive.DriveLetter):\Windows\System32\configuration\MetaConfig.mof"
    }
        }
        finally
        {
            $mountedOsDisk | Dismount-VHD
        }
    }

    Write-ProgressIndicator
    #>

    Set-LWVMDescription -ComputerName $Machine.ResourceName -Hashtable @{
        CreatedBy    = '{0} ({1})' -f $PSCmdlet.MyInvocation.MyCommand.Module.Name, $PSCmdlet.MyInvocation.MyCommand.Module.Version
        CreationTime = Get-Date
        LabName      = (Get-Lab).Name
        InitState    = [AutomatedLab.LabVMInitState]::Uninitialized
    }

    Write-PSFMessage "`tMachine '$Name' created"

    #copy AL tools to lab machine and optionally the tools folder
    #TODO
    <#
    $drive = New-PSDrive -Name $VhdVolume[0] -PSProvider FileSystem -Root $VhdVolume

    Write-PSFMessage 'Copying AL tools to VHD...'
    $tempPath = "$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tempPath | Out-Null
    Copy-Item -Path "$((Get-Module -Name AutomatedLabCore)[0].ModuleBase)\Tools\HyperV\*" -Destination $tempPath -Recurse

    Copy-Item -Path "$tempPath\*" -Destination "$vhdVolume\Windows" -Recurse

    Remove-Item -Path $tempPath -Recurse -ErrorAction SilentlyContinue

    Write-PSFMessage '...done'
    #>

    if ($Machine.OperatingSystemType -eq 'Windows' -and -not [string]::IsNullOrEmpty($Machine.SshPublicKey))
    {
        Add-UnattendedSynchronousCommand -Command 'PowerShell -File "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"' -Description 'Configure SSH'
        Add-UnattendedSynchronousCommand -Command 'PowerShell -Command "Set-Service -Name sshd -StartupType Automatic"' -Description 'Enable SSH'
        Add-UnattendedSynchronousCommand -Command 'PowerShell -Command "Restart-Service -Name sshd"' -Description 'Restart SSH'

        Write-PSFMessage 'Copying PowerShell 7 and setting up SSH'
        $release = try
        {
            Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/powershell/releases/latest' -UseBasicParsing -ErrorAction Stop
        }
        catch
        {
        }
        $uri = ($release.assets | Where-Object name -Like '*-win-x64.zip').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/PowerShell-7.2.6-win-x64.zip'
        }
        $psArchive = Get-LabInternetFile -Uri $uri -Path "$labSources/SoftwarePackages/PS7.zip"


        $release = try
        {
            Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/win32-openssh/releases/latest' -UseBasicParsing -ErrorAction Stop
        }
        catch
        {
        }
        $uri = ($release.assets | Where-Object name -Like '*-win64.zip').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.9.1.0p1-Beta/OpenSSH-Win64.zip'
        }
        $sshArchive = Get-LabInternetFile -Uri $uri -Path "$labSources/SoftwarePackages/ssh.zip"

        $null = New-Item -ItemType Directory -Force -Path (Join-Path -Path $vhdVolume -ChildPath 'Program Files\PowerShell\7')
        Expand-Archive -Path "$labSources/SoftwarePackages/PS7.zip" -DestinationPath (Join-Path -Path $vhdVolume -ChildPath 'Program Files\PowerShell\7')
        Expand-Archive -Path "$labSources/SoftwarePackages/ssh.zip" -DestinationPath (Join-Path -Path $vhdVolume -ChildPath 'Program Files')

        $null = New-Item -ItemType File -Path (Join-Path -Path $vhdVolume -ChildPath '\AL\SSH\keys'), (Join-Path -Path $vhdVolume -ChildPath 'ProgramData\ssh\sshd_config') -Force

        $Machine.SshPublicKey | Add-Content -Path (Join-Path -Path $vhdVolume -ChildPath '\AL\SSH\keys')

        $sshdConfig = @'
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
GSSAPIAuthentication yes
AllowGroups Users Administrators
AuthorizedKeysFile c:/al/ssh/keys
Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo
'@
        $sshdConfig | Set-Content -Path (Join-Path -Path $vhdVolume -ChildPath 'ProgramData\ssh\sshd_config')
        Write-PSFMessage 'Done'
    }

    #TODO: In Proxmox, this has to be done later via Copy-LabFileItem
    #if ($Machine.ToolsPath.Value)
    #{
    #    $toolsDestination = "$vhdVolume\Tools"
    #    if ($Machine.ToolsPathDestination)
    #    {
    #        $toolsDestination = "$($toolsDestination[0])$($Machine.ToolsPathDestination.Substring(1,$Machine.ToolsPathDestination.Length - 1))"
    #    }
    #    Write-PSFMessage 'Copying tools to VHD...'
    #    Copy-Item -Path $Machine.ToolsPath -Destination $toolsDestination -Recurse
    #    Write-PSFMessage '...done'
    #}

    $enableWSManRegDump = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN]
"StackVersion"="2.0"
"UpdatedConfig"="857C6BDB-A8AC-4211-93BB-8123C9ECE4E5"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Listener\*+HTTP]
"uriprefix"="wsman"
"Port"=dword:00001761

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\Event Forwarding Plugin]
"ConfigXML"="<PlugInConfiguration xmlns=\"http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration\" Name=\"Event Forwarding Plugin\" Filename=\"C:\\Windows\\system32\\wevtfwd.dll\" SDKVersion=\"1\" XmlRenderingType=\"text\" UseSharedProcess=\"false\" ProcessIdleTimeoutSec=\"0\" RunAsUser=\"\" RunAsPassword=\"\" AutoRestart=\"false\" Enabled=\"true\" OutputBufferingMode=\"Block\" ><Resources><Resource ResourceUri=\"http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog\" SupportsOptions=\"true\" ><Security Uri=\"\" ExactMatch=\"false\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GR;;;ER)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)\" /><Capability Type=\"Subscribe\" SupportsFiltering=\"true\" /></Resource></Resources><Quotas MaxConcurrentUsers=\"100\" MaxConcurrentOperationsPerUser=\"15\" MaxConcurrentOperations=\"1500\"/></PlugInConfiguration>"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\Microsoft.PowerShell]
"ConfigXML"="<PlugInConfiguration xmlns=\"http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration\" Name=\"microsoft.powershell\" Filename=\"%windir%\\system32\\pwrshplugin.dll\" SDKVersion=\"2\" XmlRenderingType=\"text\" Enabled=\"true\" Architecture=\"64\" UseSharedProcess=\"false\" ProcessIdleTimeoutSec=\"0\" RunAsUser=\"\" RunAsPassword=\"\" AutoRestart=\"false\" OutputBufferingMode=\"Block\"><InitializationParameters><Param Name=\"PSVersion\" Value=\"3.0\"/></InitializationParameters><Resources><Resource ResourceUri=\"http://schemas.microsoft.com/powershell/microsoft.powershell\" SupportsOptions=\"true\" ExactMatch=\"true\"><Security Uri=\"http://schemas.microsoft.com/powershell/microsoft.powershell\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)\" ExactMatch=\"False\"/><Capability Type=\"Shell\"/></Resource></Resources><Quotas MaxIdleTimeoutms=\"2147483647\" MaxConcurrentUsers=\"5\" IdleTimeoutms=\"7200000\" MaxProcessesPerShell=\"15\" MaxMemoryPerShellMB=\"1024\" MaxConcurrentCommandsPerShell=\"1000\" MaxShells=\"25\" MaxShellsPerUser=\"25\"/></PlugInConfiguration>"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\Microsoft.PowerShell.Workflow]
"ConfigXML"="<PlugInConfiguration xmlns=\"http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration\" Name=\"microsoft.powershell.workflow\" Filename=\"%windir%\\system32\\pwrshplugin.dll\" SDKVersion=\"2\" XmlRenderingType=\"text\" UseSharedProcess=\"true\" ProcessIdleTimeoutSec=\"28800\" RunAsUser=\"\" RunAsPassword=\"\" AutoRestart=\"false\" Enabled=\"true\" Architecture=\"64\" OutputBufferingMode=\"Block\"><InitializationParameters><Param Name=\"PSVersion\" Value=\"3.0\"/><Param Name=\"AssemblyName\" Value=\"Microsoft.PowerShell.Workflow.ServiceCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35, processorArchitecture=MSIL\"/><Param Name=\"PSSessionConfigurationTypeName\" Value=\"Microsoft.PowerShell.Workflow.PSWorkflowSessionConfiguration\"/><Param Name=\"SessionConfigurationData\" Value=\"                             &lt;SessionConfigurationData&gt;                                 &lt;Param Name=&quot;ModulesToImport&quot; Value=&quot;%windir%\\system32\\windowspowershell\\v1.0\\Modules\\PSWorkflow&quot;/&gt;                                 &lt;Param Name=&quot;PrivateData&quot;&gt;                                     &lt;PrivateData&gt;                                         &lt;Param Name=&quot;enablevalidation&quot; Value=&quot;true&quot; /&gt;                                     &lt;/PrivateData&gt;                                 &lt;/Param&gt;                             &lt;/SessionConfigurationData&gt;                         \"/></InitializationParameters><Resources><Resource ResourceUri=\"http://schemas.microsoft.com/powershell/microsoft.powershell.workflow\" SupportsOptions=\"true\" ExactMatch=\"true\"><Security Uri=\"http://schemas.microsoft.com/powershell/microsoft.powershell.workflow\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)\" ExactMatch=\"False\"/><Capability Type=\"Shell\"/></Resource></Resources><Quotas MaxIdleTimeoutms=\"2147483647\" MaxConcurrentUsers=\"5\" IdleTimeoutms=\"7200000\" MaxProcessesPerShell=\"15\" MaxMemoryPerShellMB=\"1024\" MaxConcurrentCommandsPerShell=\"1000\" MaxShells=\"25\" MaxShellsPerUser=\"25\"/></PlugInConfiguration>"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\Microsoft.PowerShell32]
"ConfigXML"="<PlugInConfiguration xmlns=\"http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration\" Name=\"microsoft.powershell32\" Filename=\"%windir%\\system32\\pwrshplugin.dll\" SDKVersion=\"2\" XmlRenderingType=\"text\" Architecture=\"32\" Enabled=\"true\" UseSharedProcess=\"false\" ProcessIdleTimeoutSec=\"0\" RunAsUser=\"\" RunAsPassword=\"\" AutoRestart=\"false\" OutputBufferingMode=\"Block\"><InitializationParameters><Param Name=\"PSVersion\" Value=\"3.0\"/></InitializationParameters><Resources><Resource ResourceUri=\"http://schemas.microsoft.com/powershell/microsoft.powershell32\" SupportsOptions=\"true\" ExactMatch=\"true\"><Security Uri=\"http://schemas.microsoft.com/powershell/microsoft.powershell32\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)\" ExactMatch=\"False\"/><Capability Type=\"Shell\"/></Resource></Resources><Quotas MaxIdleTimeoutms=\"2147483647\" MaxConcurrentUsers=\"5\" IdleTimeoutms=\"7200000\" MaxProcessesPerShell=\"15\" MaxMemoryPerShellMB=\"1024\" MaxConcurrentCommandsPerShell=\"1000\" MaxShells=\"25\" MaxShellsPerUser=\"25\"/></PlugInConfiguration>"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Plugin\WMI Provider]
"ConfigXML"="<PlugInConfiguration xmlns=\"http://schemas.microsoft.com/wbem/wsman/1/config/PluginConfiguration\" Name=\"WMI Provider\" Filename=\"C:\\Windows\\system32\\WsmWmiPl.dll\" SDKVersion=\"1\" XmlRenderingType=\"text\" UseSharedProcess=\"false\" ProcessIdleTimeoutSec=\"0\" RunAsUser=\"\" RunAsPassword=\"\" AutoRestart=\"false\" Enabled=\"true\" OutputBufferingMode=\"Block\" ><Resources><Resource ResourceUri=\"http://schemas.microsoft.com/wbem/wsman/1/wmi\" SupportsOptions=\"true\" ><Security Uri=\"\" ExactMatch=\"false\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)\" /><Capability Type=\"Identify\" /><Capability Type=\"Get\" SupportsFragment=\"true\" /><Capability Type=\"Put\" SupportsFragment=\"true\" /><Capability Type=\"Invoke\" /><Capability Type=\"Create\" /><Capability Type=\"Delete\" /><Capability Type=\"Enumerate\" SupportsFiltering=\"true\"/><Capability Type=\"Subscribe\" SupportsFiltering=\"true\"/></Resource><Resource ResourceUri=\"http://schemas.dmtf.org/wbem/wscim/1/cim-schema\" SupportsOptions=\"true\" ><Security Uri=\"\" ExactMatch=\"false\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)\" /><Capability Type=\"Get\" SupportsFragment=\"true\" /><Capability Type=\"Put\" SupportsFragment=\"true\" /><Capability Type=\"Invoke\" /><Capability Type=\"Create\" /><Capability Type=\"Delete\" /><Capability Type=\"Enumerate\"/><Capability Type=\"Subscribe\" SupportsFiltering=\"true\"/></Resource><Resource ResourceUri=\"http://schemas.dmtf.org/wbem/wscim/1/*\" SupportsOptions=\"true\" ExactMatch=\"true\" ><Security Uri=\"\" ExactMatch=\"false\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)\" /><Capability Type=\"Enumerate\" SupportsFiltering=\"true\"/><Capability Type=\"Subscribe\"SupportsFiltering=\"true\"/></Resource><Resource ResourceUri=\"http://schemas.dmtf.org/wbem/cim-xml/2/cim-schema/2/*\" SupportsOptions=\"true\" ExactMatch=\"true\"><Security Uri=\"\" ExactMatch=\"false\" Sddl=\"O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GWGX;;;WD)\" /><Capability Type=\"Get\" SupportsFragment=\"false\"/><Capability Type=\"Enumerate\" SupportsFiltering=\"true\"/></Resource></Resources><Quotas MaxConcurrentUsers=\"100\" MaxConcurrentOperationsPerUser=\"100\" MaxConcurrentOperations=\"1500\"/></PlugInConfiguration>"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Service]
"allow_remote_requests"=dword:00000001
'@
    #Using the .net class as the PowerShell provider usually does not recognize the new drive
    [System.IO.File]::WriteAllText("$vhdVolume\WSManRegKey.reg", $enableWSManRegDump)

    $additionalDisksOnline = @'
Start-Transcript -Path C:\DeployDebug\AdditionalDisksOnline.log
$diskpartCmd = 'LIST DISK'
$disks = $diskpartCmd | diskpart.exe
$pattern = 'Disk (?<DiskNumber>\d{1,3}) \s+(?<State>Online|Offline)\s+(?<Size>\d+) (KB|MB|GB|TB)\s+(?<Free>\d+) (B|KB|MB|GB|TB)'
foreach ($line in $disks)
{
    if ($line -match $pattern)
    {
        $diskNumber = $Matches.DiskNumber
        if ($Matches.State -eq 'Offline')
        {
            $diskpartCmd = "@
                SELECT DISK $diskNumber
                ATTRIBUTES DISK CLEAR READONLY
                ONLINE DISK
                EXIT
            @"
            $diskpartCmd | diskpart.exe | Out-Null
        }
    }
}

$diskDefinitions = Import-Clixml -Path C:\Disks.xml
Write-Verbose -Message "Disk count for $env:COMPUTERNAME`: $($diskDefinitions.Count)"
foreach ($diskDefinition in $diskDefinitions | Where-Object { -not $_.SkipInitialization })
{
    $disk = Get-Disk | Where-Object Number -eq $diskDefinition.Lun
    $disk | Set-Disk -IsReadOnly $false
    $disk | Set-Disk -IsOffline $false
    $disk | Initialize-Disk -PartitionStyle GPT
    $partition = if ($diskDefinition.DriveLetter)
    {
        $disk | New-Partition -UseMaximumSize -DriveLetter $diskDefinition.DriveLetter
    }
    else
    {
        $disk | New-Partition -UseMaximumSize -AssignDriveLetter
    }
    $partition | Format-Volume -Force -UseLargeFRS:$diskDefinition.UseLargeFRS -AllocationUnitSize $diskDefinition.AllocationUnitSize -NewFileSystemLabel $diskDefinition.Label
}

Stop-Transcript
'@
    [System.IO.File]::WriteAllText("$vhdVolume\AdditionalDisksOnline.ps1", $additionalDisksOnline)

    $defaultSettings = @{
        WinRmMaxEnvelopeSizeKb              = 500
        WinRmMaxConcurrentOperationsPerUser = 1500
        WinRmMaxConnections                 = 300
    }

    $command = 'Start-Service WinRm'
    foreach ($setting in $defaultSettings.GetEnumerator())
    {
        $settingValue = if ((Get-LabConfigurationItem -Name $setting.Key) -ne $setting.Value)
        {
            Get-LabConfigurationItem -Name $setting.Key
        }
        else
        {
            $setting.Value
        }

        $subdir = if ($setting.Key -match 'MaxEnvelope')
        {
            $null
        }
        else
        {
            'Service\'
        }
        $command = -join @($command, "`r`nSet-Item WSMAN:\localhost\$subdir$($setting.Key.Replace('WinRm','')) $($settingValue) -Force")
    }

    [System.IO.File]::WriteAllText("$vhdVolume\WinRmCustomization.ps1", $command)

    Write-ProgressIndicator

    $unattendXmlContent = Get-UnattendedContent
    $unattendXmlContent.Save("$VhdVolume\Unattend.xml")
    Write-PSFMessage "`tUnattended file copied to VM Disk '$vhdVolume\unattend.xml'"

    Start-LWProxmoxVM -ComputerName $Machine

    Write-Verbose "Waiting for QEMU Guest Agent to become available on VM '$($Machine.ResourceName)'..."
    $agentTimeout = Get-LabConfigurationItem -Name ProxmoxAgentTimeout -Default 300
    $agentTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $previousEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    while ((New-PveNodesQemuAgentPing -Node $Machine.ProxmoxProperties.TargetNode -Vmid $nextVmId).StatusCode -ne 200)
    {
        if ($agentTimer.Elapsed.TotalSeconds -ge $agentTimeout)
        {
            Write-PSFMessage -Level Warning -Message "QEMU Guest Agent on VM '$($Machine.ResourceName)' did not respond within $agentTimeout seconds. Continuing without agent-based provisioning."
            break
        }
        Start-Sleep -Seconds 1
    }
    $ErrorActionPreference = $previousEAP
    $agentTimer.Stop()
    $agentAvailable = $agentTimer.Elapsed.TotalSeconds -lt $agentTimeout

    if ($agentAvailable)
    {
        # Allow the QEMU guest agent to fully initialize file-operation handlers.
        # On some Proxmox templates the agent responds to ping before it can process
        # file-write or exec requests, causing avoidable retry delays.
        $stabilizationSeconds = Get-LabConfigurationItem -Name ProxmoxAgentStabilizationSeconds -Default 10
        Write-PSFMessage "QEMU Guest Agent responded after $([int]$agentTimer.Elapsed.TotalSeconds)s. Waiting ${stabilizationSeconds}s for agent to stabilize on VM '$($Machine.ResourceName)'."
        Start-Sleep -Seconds $stabilizationSeconds
    }
    Write-Verbose 'done.'

    if ($agentAvailable)
    {
        $files = dir -Path $vhdVolume -File
        foreach ($file in $files)
        {
            Write-PSFMessage "Copying file '$($file.Name)' to VM '$($Machine.ResourceName)'"
            Send-LWProxmoxFileCopyToVM -SourceFilePath $file.FullName -ComputerName $Machine.ResourceName
        }

        # Set SkipRearm to prevent Sysprep from calling SLReArmWindows which can fail
        # with 0xc004f075 (SL_E_SLC_STOPPING) when sppsvc is not yet fully started.
        Write-PSFMessage "Setting SkipRearm on VM '$($Machine.ResourceName)' to prevent licensing rearm race condition"
        Start-LWProxmoxAgentExecutionOnVM -ComputerName $Machine.ResourceName -Command 'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareLicensingService" /v SkipRearm /t REG_DWORD /d 1 /f'
        Start-Sleep -Seconds 2

        Write-PSFMessage "Starting Sysprep on VM '$($Machine.ResourceName)'"
        Start-LWProxmoxAgentExecutionOnVM -ComputerName $Machine.ResourceName -Command 'C:\Windows\system32\Sysprep\sysprep.exe /generalize /oobe /reboot'
    }
    else
    {
        Write-PSFMessage -Level Warning -Message "Skipping agent-based provisioning (file copy, SkipRearm, Sysprep) for VM '$($Machine.ResourceName)' because QEMU Guest Agent is not available."
    }

    #TODO: This needs to move to the New-LabVM function
    <#
    Write-PSFMessage "Creating snapshot named '$($Machine.ResourceName) - post OS Installation'"
    if ($CreateCheckPoints)
    {
        Hyper-V\Checkpoint-VM -VM (Hyper-V\Get-VM -Name $Machine.ResourceName) -SnapshotName 'Post OS Installation'
    }
    #>

    #TODO ...
    <#
    if ($Machine.Disks.Name)
    {
        $disks = Get-LabVHDX -Name $Machine.Disks.Name
        foreach ($disk in $disks)
        {
            Add-LWVMVHDX -VMName $Machine.ResourceName -VhdxPath $disk.Path
        }
    }
    #>

    Write-ProgressIndicatorEnd

    #TODO: ...
    <#
    $writeVmConnectConfigFile = Get-LabConfigurationItem -Name VMConnectWriteConfigFile
    if ($writeVmConnectConfigFile)
    {
        New-LWHypervVmConnectSettingsFile -VmName $Machine.ResourceName
    }
    #>

    Write-LogFunctionExit

    return $true
}
