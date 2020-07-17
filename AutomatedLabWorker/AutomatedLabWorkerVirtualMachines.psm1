trap
{
    if ((($_.Exception.Message -like '*Get-VM*') -or `
            ($_.Exception.Message -like '*Save-VM*') -or `
            ($_.Exception.Message -like '*Get-VMSnapshot*') -or `
            ($_.Exception.Message -like '*Suspend-VM*') -or `
    ($_.Exception.Message -like '*CheckPoint-VM*')) -and (-not (Get-Module -ListAvailable Hyper-V)))
    {
    }
    else
    {
        Write-Error $_
    }
    continue
}

#region New-LWHypervVM
function New-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $PSBoundParameters.Add('ProgressIndicator', 1) #enables progress indicator

    Write-LogFunctionEntry

    $script:lab = Get-Lab

    if (Get-VM -Name $Machine.ResourceName -ErrorAction SilentlyContinue)
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "The machine '$Machine' does already exist" -Type Warning
        return $false
    }

    if ($PSDefaultParameterValues.ContainsKey('*:IsKickstart')) { $PSDefaultParameterValues.Remove('*:IsKickstart') }
    if ($PSDefaultParameterValues.ContainsKey('*:IsAutoYast')) { $PSDefaultParameterValues.Remove('*:IsAutoYast') }

    if ($Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'RedHat')
    {
        $PSDefaultParameterValues['*:IsKickstart'] = $true
    }
    if($Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'Suse')
    {
        $PSDefaultParameterValues['*:IsAutoYast'] = $true
    }

    Write-PSFMessage "Creating machine with the name '$($Machine.ResourceName)' in the path '$VmPath'"

    #region Unattend XML settings
    if (-not $Machine.ProductKey)
    {
        $Machine.ProductKey = $Machine.OperatingSystem.ProductKey
    }

    Import-UnattendedContent -Content $Machine.UnattendedXmlContent

    #region network adapter settings
    $macAddressPrefix = Get-LabConfigurationItem -Name MacAddressPrefix
    $macAddressesInUse = @(Get-VM | Get-VMNetworkAdapter | Select-Object -ExpandProperty MacAddress)
    $macAddressesInUse += (Get-LabVm -IncludeLinux).NetworkAdapters.MacAddress

    $macIdx = 0
    while ("$macAddressPrefix{0:X6}" -f $macIdx -in $macAddressesInUse) { $macIdx++ }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.NetworkAdapter
    $adapters = New-Object $type
    $Machine.NetworkAdapters | Where-Object { $_.Ipv4Address } | Sort-Object -Property { $_.Ipv4Address[0] } | ForEach-Object {$adapters.Add($_)}
    $Machine.NetworkAdapters | Where-Object { -not $_.Ipv4Address } | ForEach-Object {$adapters.Add($_)}

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

    foreach ($adapter in $adapters)
    {
        $ipSettings = @{}

        $mac = "$macAddressPrefix{0:X6}" -f $macIdx++

        $ipSettings.Add('MacAddress', $mac)
        $adapter.MacAddress = $mac

        $macWithDash = '{0}-{1}-{2}-{3}-{4}-{5}' -f $mac.Substring(0, 2),
        $mac.Substring(2, 2),
        $mac.Substring(4, 2),
        $mac.Substring(6, 2),
        $mac.Substring(8, 2),
        $mac.Substring(10, 2)

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

        if (-not $Machine.IsDomainJoined -and (-not $adapter.ConnectionSpecificDNSSuffix))
        {
            $rootDomainName = Get-LabVM -Role RootDC | Select-Object -First 1 | Select-Object -ExpandProperty DomainName
            $ipSettings.Add('DnsDomain', $rootDomainName)
        }

        if ($adapter.ConnectionSpecificDNSSuffix) { $ipSettings.Add('DnsDomain', $adapter.ConnectionSpecificDNSSuffix) }
        $ipSettings.Add('UseDomainNameDevolution', (([string]($adapter.AppendParentSuffixes)) = 'true'))
        if ($adapter.AppendDNSSuffixes)           { $ipSettings.Add('DNSSuffixSearchOrder', $adapter.AppendDNSSuffixes -join ',') }
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

        switch ($Adapter.NetbiosOptions)
        {
            'Default'  { $ipSettings.Add('NetBIOSOptions', '0') }
            'Enabled'  { $ipSettings.Add('NetBIOSOptions', '1') }
            'Disabled' { $ipSettings.Add('NetBIOSOptions', '2') }
        }

        Add-UnattendedNetworkAdapter @ipSettings
    }

    $Machine.NetworkAdapters = $adapters

    if ($Machine.OperatingSystemType -eq 'Windows') {Add-UnattendedRenameNetworkAdapters}
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
            $domain = $lab.Domains | Where-Object Name -eq $Machine.DomainName

            $parameters = @{
                DomainName = $Machine.DomainName
                Username = $domain.Administrator.UserName
                Password = $domain.Administrator.Password
            }
            if ($Machine.OperatingSystemType -eq 'Linux')
            {
                $parameters['IsKickstart'] = $Machine.LinuxType -eq 'RedHat'
                $parameters['IsAutoYast'] = $Machine.LinuxType -eq 'Suse'
            }

            Set-UnattendedDomain @parameters

            if ($Machine.OperatingSystemType -eq 'Linux')
            {
                $sudoParam = @{
                    Command = "sed -i '/^%wheel.*/a %$($Machine.DomainName.ToUpper())\\\\domain\\ admins ALL=(ALL) NOPASSWD: ALL' /etc/sudoers"
                    Description = 'Enable domain admin as sudoer without password'
                }

                Add-UnattendedSynchronousCommand @sudoParam
            }
        }
    }

    #set the Generation for the VM depending on SupportGen2VMs, host OS version and VM OS version
    $hostOsVersion = [System.Environment]::OSVersion.Version

    $generation = if (Get-LabConfigurationItem -Name SupportGen2VMs)
    {
        if ($hostOsVersion -ge [System.Version]6.3 -and $Machine.Gen2VmSupported)
        {
            2
        }
        else
        {
            1
        }
    }
    else
    {
        1
    }

    $vmPath = $lab.GetMachineTargetPath($Machine.ResourceName)
    $path = "$vmPath\$($Machine.ResourceName).vhdx"
    Write-PSFMessage "`tVM Disk path is '$path'"

    if (Test-Path -Path $path)
    {
        Write-ScreenInfo -Message "The disk $path does already exist. Disk cannot be created" -Type Warning
        return $false
    }

    Write-ProgressIndicator

    if ($Machine.OperatingSystemType -eq 'Linux')
    {
        $nextDriveLetter = [char[]](67..90) |
        Where-Object { (Get-CimInstance -Class Win32_LogicalDisk |
        Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} |
        Select-Object -First 1
        $systemDisk = New-Vhd -Path $path -SizeBytes ($lab.Target.ReferenceDiskSizeInGB * 1GB) -BlockSizeBytes 1MB
        $mountedOsDisk = $systemDisk | Mount-VHD -Passthru
        $mountedOsDisk | Initialize-Disk -PartitionStyle GPT
        $size = 6GB
        if ($Machine.LinuxType -eq 'RedHat')
        {
            $size = 100MB
        }
        $unattendPartition = $mountedOsDisk | New-Partition -Size $size

        # Use a small FAT32 partition to hold AutoYAST and Kickstart configuration
        $diskpartCmd = "@
            select disk $($mountedOsDisk.DiskNumber)
            select partition $($unattendPartition.PartitionNumber)
            format quick fs=fat32 label=OEMDRV
            exit
        @"
        $diskpartCmd | diskpart.exe | Out-Null

        $unattendPartition | Set-Partition -NewDriveLetter $nextDriveLetter
        $unattendPartition = $unattendPartition | Get-Partition
        $drive = [System.IO.DriveInfo][string]$unattendPartition.DriveLetter

        if ( $machine.LinuxPackageGroup )
        {
            Set-UnattendedPackage -Package $machine.LinuxPackageGroup
        }

        # Copy Unattend-Stuff here
        if ($Machine.LinuxType -eq 'RedHat')
        {
            Export-UnattendedFile -Path (Join-Path -Path $drive.RootDirectory -ChildPath ks.cfg)
            Export-UnattendedFile -Path (Join-Path -Path $script:lab.Sources.UnattendedXml.Value -ChildPath "ks_$($Machine.Name).cfg")
        }
        else
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

            # Copy additional packages
            $additionalPackagePath = (Join-Path -Path $global:Labsources -ChildPath "$($machine.OperatingSystem.OperatingSystemName)\$($machine.OperatingSystem.Version.ToString(2))\*.*")
            if (Test-Path -Path $additionalPackagePath)
            {
                switch -Regex ($Machine.OperatingSystem.OperatingSystemName)
                {
                    'Suse'
                    {
                        Copy-Item -Path $additionalPackagePath -Destination "$letter`:\suse\x86_64" -Force
                    }
                    'Red Hat|Centos'
                    {
                        Copy-Item -Path $additionalPackagePath -Destination "$letter`:\Packages" -Force
                    }
                    'Fedora'
                    {
                        # Why...
                        Get-ChildItem $additionalPackagePath -File | ForEach-Object {
                            $targetPath = Join-Path -Path "$letter`:\Packages" -ChildPath $_.Name.Substring(0, 1)
                            $_ | Copy-Item -Destination $targetPath -Force
                        }
                    }
                }
            }

            # AutoYast XML file is not picked up properly without modifying bootloader config
            # Change grub and isolinux configuration
            $grubFile = Get-ChildItem -Recurse -Path $drive.RootDirectory.FullName -Filter 'grub.cfg'
            $isolinuxFile = Get-ChildItem -Recurse -Path $drive.RootDirectory.FullName -Filter 'isolinux.cfg'

            ($grubFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 autoyast=device:///autoinst.xml" | Set-Content -Path $grubFile.FullName
            ($isolinuxFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 autoyast=device:///autoinst.xml" | Set-Content -Path $isolinuxFile.FullName
        }

        $mountedOsDisk | Dismount-VHD

        if ($PSDefaultParameterValues.ContainsKey('*:IsKickstart')) { $PSDefaultParameterValues.Remove('*:IsKickstart') }
        if ($PSDefaultParameterValues.ContainsKey('*:IsAutoYast')) { $PSDefaultParameterValues.Remove('*:IsAutoYast') }
    }
    else
    {
        $referenceDiskPath = $Machine.OperatingSystem.BaseDiskPath
        $systemDisk = New-VHD -Path $path -Differencing -ParentPath $referenceDiskPath -ErrorAction Stop
        Write-PSFMessage "`tcreated differencing disk '$($systemDisk.Path)' pointing to '$ReferenceVhdxPath'"
    }

    Write-ProgressIndicator

    $vmParameter = @{
        Name = $Machine.ResourceName
        MemoryStartupBytes = ($Machine.Memory)
        VHDPath = $systemDisk.Path
        Path = $VmPath
        Generation = $generation
        ErrorAction = 'Stop'
    }

    $vm = New-VM @vmParameter

    Set-LWHypervVMDescription -ComputerName $Machine.ResourceName -Hashtable @{
        CreatedBy = '{0} ({1})' -f $PSCmdlet.MyInvocation.MyCommand.Module.Name, $PSCmdlet.MyInvocation.MyCommand.Module.Version
        CreationTime = Get-Date
        LabName = (Get-Lab).Name
        InitState = [AutomatedLab.LabVMInitState]::Uninitialized
    }

    #Removing this check as this 'Get-SecureBootUEFI' is not supported on Azure VMs for nested virtualization
    #$isUefi = try
    #{
    #    Get-SecureBootUEFI -Name SetupMode
    #}
    #catch { }

    if ($vm.Generation -ge 2)
    {
        $secureBootTemplate = if ($Machine.HypervProperties.SecureBootTemplate)
        {
            $Machine.HypervProperties.SecureBootTemplate
        }
        else
        {
            if ($Machine.LinuxType -eq 'unknown')
            {
                'MicrosoftWindows'
            }
            else
            {
                'MicrosoftUEFICertificateAuthority'
            }
        }
        if ($Machine.HypervProperties.EnableSecureBoot)
        {
            $vm | Set-VMFirmware -EnableSecureBoot On -SecureBootTemplate $secureBootTemplate
        }
        else
        {
            $vm | Set-VMFirmware -EnableSecureBoot Off
        }
    }

    #remove the unconnected default network adapter
    $vm | Remove-VMNetworkAdapter
    foreach ($adapter in $adapters)
    {
        #bind all network adapters to their designated switches, Repair-LWHypervNetworkConfig will change the binding order if necessary
        $newAdapter = Add-VMNetworkAdapter -Name $adapter.VirtualSwitch.ResourceName -SwitchName $adapter.VirtualSwitch.ResourceName -StaticMacAddress $adapter.MacAddress -VMName $vm.Name -PassThru

        if (-not $adapter.AccessVLANID -eq 0) {

            Set-VMNetworkAdapterVlan -VMNetworkAdapter $newAdapter -Access -VlanId $adapter.AccessVLANID
            Write-PSFMessage "Network Adapter: '$($adapter.VirtualSwitch.ResourceName)' for VM: '$($vm.Name)' created with VLAN ID: '$($adapter.AccessVLANID)', Ensure external routing is configured correctly"
        }
    }

    Write-PSFMessage "`tMachine '$Name' created"

    $automaticStartAction = 'Nothing'
    $automaticStartDelay  = 0
    $automaticStopAction  = 'ShutDown'

    if ($Machine.HypervProperties.AutomaticStartAction) { $automaticStartAction = $Machine.HypervProperties.AutomaticStartAction }
    if ($Machine.HypervProperties.AutomaticStartDelay)  { $automaticStartDelay  = $Machine.HypervProperties.AutomaticStartDelay  }
    if ($Machine.HypervProperties.AutomaticStopAction)  { $automaticStopAction  = $Machine.HypervProperties.AutomaticStopAction  }
    $vm | Set-VM -AutomaticStartAction $automaticStartAction -AutomaticStartDelay $automaticStartDelay -AutomaticStopAction $automaticStopAction

    Write-ProgressIndicator

    if ( $Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -eq 'RedHat')
    {
        $vm | Add-VMDvdDrive -Path $Machine.OperatingSystem.IsoPath
    }

    if ( $Machine.OperatingSystemType -eq 'Windows')
    {
        [void] (Mount-DiskImage -ImagePath $path)
        $VhdDisk = Get-DiskImage -ImagePath $path | Get-Disk
        $VhdPartition = Get-Partition -DiskNumber $VhdDisk.Number

        if ($VhdPartition.Count -gt 1)
        {
            #for Generation 2 VMs
            $vhdOsPartition = $VhdPartition | Where-Object Type -eq 'Basic'
            # If no drive letter is assigned, make sure we assign it before continuing
            If ($vhdOsPartition.NoDefaultDriveLetter) {
                # Get all available drive letters, and store in a temporary variable.
                $usedDriveLetters = @(Get-Volume | ForEach-Object { "$([char]$_.DriveLetter)" }) + @(Get-CimInstance -ClassName Win32_MappedLogicalDisk | ForEach-Object { $([char]$_.DeviceID.Trim(':')) })
                [char[]]$tempDriveLetters = Compare-Object -DifferenceObject $usedDriveLetters -ReferenceObject $( 67..90 | ForEach-Object { "$([char]$_)" }) -PassThru | Where-Object { $_.SideIndicator -eq '<=' }
                # Sort the available drive letters to get the first available drive letter
                $availableDriveLetters = ($TempDriveLetters | Sort-Object)
                $firstAvailableDriveLetter = $availableDriveLetters[0]
                $vhdOsPartition | Set-Partition -NewDriveLetter $firstAvailableDriveLetter
                $VhdVolume = "$($firstAvailableDriveLetter):"

            }
            Else
            {
                $VhdVolume = "$($vhdOsPartition.DriveLetter):"
            }
        }
        else
        {
            #for Generation 1 VMs
            $VhdVolume = "$($VhdPartition.DriveLetter):"
        }

        #Get-PSDrive needs to be called to update the PowerShell drive list
        Get-PSDrive | Out-Null

        Write-PSFMessage "`tDisk mounted to drive $VhdVolume"
        $unattendXmlContent = Get-UnattendedContent
        $unattendXmlContent.Save("$VhdVolume\Unattend.xml")
        Write-PSFMessage "`tUnattended file copied to VM Disk '$vhdVolume\unattend.xml'"

        #copy AL tools to lab machine and optionally the tools folder
        $drive = New-PSDrive -Name $VhdVolume[0] -PSProvider FileSystem -Root $VhdVolume

        Write-PSFMessage 'Copying AL tools to VHD...'
        $tempPath = "$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $tempPath | Out-Null
        Copy-Item -Path "$((Get-Module -Name AutomatedLab)[0].ModuleBase)\Tools\HyperV\*" -Destination $tempPath -Recurse
        foreach ($file in (Get-ChildItem -Path $tempPath -Recurse -File))
        {
            # Why???
            if ($PSEdition -eq 'Desktop')
            {
                $file.Decrypt()
            }
        }
        Copy-Item -Path "$tempPath\*" -Destination "$vhdVolume\Windows" -Recurse

        Remove-Item -Path $tempPath -Recurse

        Write-PSFMessage '...done'

        if ($Machine.ToolsPath.Value)
        {
            $toolsDestination = "$vhdVolume\Tools"
            if ($Machine.ToolsPathDestination)
            {
                $toolsDestination = "$($toolsDestination[0])$($Machine.ToolsPathDestination.Substring(1,$Machine.ToolsPathDestination.Length - 1))"
            }
            Write-PSFMessage 'Copying tools to VHD...'
            Copy-Item -Path $Machine.ToolsPath -Destination $toolsDestination -Recurse
            Write-PSFMessage '...done'
        }

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
 foreach ($line in $disks)
{
    if ($line -match 'Disk (?<DiskNumber>\d) \s+(?<State>Online|Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) (B|GB)')
    {
        #$nextDriveLetter = [char[]](67..90) |
        #Where-Object { (Get-CimInstance -Class Win32_LogicalDisk |
        #Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} |
        #Select-Object -First 1
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
 foreach ($volume in (Get-WmiObject -Class Win32_Volume))
{
    if ($volume.Label -notmatch '(?<Label>[\w\d]+)_AL_(?<DriveLetter>[A-Z])')
    {
        continue
    }
     if ($volume.DriveLetter -ne "$($Matches.DriveLetter):")
    {
        $volume.DriveLetter = "$($Matches.DriveLetter):"
    }
     $volume.Label = $Matches.Label
    $volume.Put()
}
Stop-Transcript
'@
        [System.IO.File]::WriteAllText("$vhdVolume\AdditionalDisksOnline.ps1", $additionalDisksOnline)

        [void] (Dismount-DiskImage -ImagePath $path)
        Write-PSFMessage "`tdisk image dismounted"

        Write-ProgressIndicator
    }

    Write-PSFMessage "`tSettings RAM, start and stop actions"
    $param = @{}
    $param.Add('MemoryStartupBytes', $Machine.Memory)
    $param.Add('AutomaticCheckpointsEnabled', $false)
    $param.Add('CheckpointType', 'Production')

    if ($Machine.MaxMemory) { $param.Add('MemoryMaximumBytes', $Machine.MaxMemory) }
    if ($Machine.MinMemory) { $param.Add('MemoryMinimumBytes', $Machine.MinMemory) }

    if ($Machine.MaxMemory -or $Machine.MinMemory)
    {
        $param.Add('DynamicMemory', $true)
        Write-PSFMessage "`tSettings dynamic memory to MemoryStartupBytes $($Machine.Memory), minimum $($Machine.MinMemory), maximum $($Machine.MaxMemory)"
    }
    else
    {
        Write-PSFMessage "`tSettings static memory to $($Machine.Memory)"
        $param.Add('StaticMemory', $true)
    }

    $param = Sync-Parameter -Command (Get-Command Set-Vm) -Parameters $param

    Set-VM -Name $Machine.ResourceName @param

    Set-VM -Name $Machine.ResourceName -ProcessorCount $Machine.Processors

    if ($DisableIntegrationServices)
    {
        Disable-VMIntegrationService -VMName $Machine.ResourceName -Name 'Time Synchronization'
    }

    if ($Generation -eq 1)
    {
        Set-VMBios -VMName $Machine.ResourceName -EnableNumLock
    }

    Write-PSFMessage "Creating snapshot named '$($Machine.ResourceName) - post OS Installation'"
    if ($CreateCheckPoints)
    {
        Checkpoint-VM -VM (Get-VM -Name $Machine.ResourceName) -SnapshotName 'Post OS Installation'
    }

    if ($Machine.Disks.Name)
    {
        $disks = Get-LabVHDX -Name $Machine.Disks.Name
        foreach ($disk in $disks)
        {
            Add-LWVMVHDX -VMName $Machine.ResourceName -VhdxPath $disk.Path
        }
    }

    Write-ProgressIndicatorEnd

    Write-LogFunctionExit

    return $true
}
#endregion New-LWHypervVM

#region Remove-LWHypervVM
function Remove-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    Param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if ($vm)
    {
        $vmPath = Split-Path -Path $vm.HardDrives[0].Path -Parent

        if ($vm.State -eq 'Saved')
        {
            Write-PSFMessage "Deleting saved state of VM '$($Name)'"
            Remove-VMSavedState -VMName $Name
        }
        else
        {
            Write-PSFMessage "Stopping VM '$($Name)'"
            Stop-VM -TurnOff -Name $Name -Force -WarningAction SilentlyContinue
        }

        Write-PSFMessage "Removing VM '$($Name)'"
        Remove-VM -Name $Name -Force

        Write-PSFMessage "Removing VM files for '$($Name)'"
        Remove-Item -Path $vmPath -Force -Confirm:$false -Recurse
    }

    Write-LogFunctionExit
}
#endregion Remove-LWHypervVM

#region Wait-LWHypervVMRestart
function Wait-LWHypervVMRestart
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes = 15,

        [ValidateRange(1, 300)]
        [int]$ProgressIndicator,

        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting,

        [System.Management.Automation.Job[]]$MonitorJob,

        [switch]$NoNewLine
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName -IncludeLinux

    $machines | Add-Member -Name Uptime -MemberType NoteProperty -Value 0 -Force
    foreach ($machine in $machines)
    {
        $machine.Uptime = (Get-VM -Name $machine.ResourceName).Uptime.TotalSeconds
    }

    $vmDrive = ((Get-Lab).Target.Path)[0]
    $start = (Get-Date)
    $progressIndicatorStart = (Get-Date)
    $diskTime = @()
    $lastMachineStart = (Get-Date).AddSeconds(-5)
    $delayedStart = @()

    #$lastMonitorJob = (Get-Date)

    do
    {
        if (((Get-Date) - $progressIndicatorStart).TotalSeconds -gt $ProgressIndicator)
        {
            Write-ProgressIndicator
            $progressIndicatorStart = (Get-Date)
        }

        $diskTime += 100-([int](((Get-Counter -counter "\\$(hostname.exe)\PhysicalDisk(*)\% Idle Time" -SampleInterval 1).CounterSamples | Where-Object {$_.InstanceName -like "*$vmDrive`:*"}).CookedValue))

        if ($StartMachinesWhileWaiting)
        {
            if ($StartMachinesWhileWaiting[0].NetworkAdapters.Count -gt 1)
            {
                $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                $delayedStart += $StartMachinesWhileWaiting[0]
            }
            else
            {
                Write-Debug -Message "Disk Time: $($diskTime[-1]). Average (20): $([int](($diskTime[(($diskTime).Count-15)..(($diskTime).Count)] | Measure-Object -Average).Average)) - Average (5): $([int](($diskTime[(($diskTime).Count-5)..(($diskTime).Count)] | Measure-Object -Average).Average))"
                if (((Get-Date) - $lastMachineStart).TotalSeconds -ge 20)
                {
                    if (($diskTime[(($diskTime).Count - 15)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 50 -and ($diskTime[(($diskTime).Count-5)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 60)
                    {
                        Write-PSFMessage -Message 'Starting next machine'
                        $lastMachineStart = (Get-Date)
                        Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
                        $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                        if ($StartMachinesWhileWaiting)
                        {
                            Start-LabVM -ComputerName $StartMachinesWhileWaiting[0] -NoNewline:$NoNewLine
                            $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                        }
                    }
                }
            }
        }
        else
        {
            Start-Sleep -Seconds 1
        }

        <#
                Not implemented yet as receive-job displays everything in the console
                if ($lastMonitorJob -and ((Get-Date) - $lastMonitorJob).TotalSeconds -ge 5)
                {
                foreach ($job in $MonitorJob)
                {
                try
                {
                $dummy = Receive-Job -Keep -Id $job.ID -ErrorAction Stop
                }
                catch
                {
                Write-ScreenInfo -Message "Something went wrong with '$($job.Name)'. Please check using 'Receive-Job -Id $($job.Id)'" -Type Error
                throw 'Execution stopped'
                }
                }
                }
        #>

        foreach ($machine in $machines)
        {
            $currentMachineUptime = (Get-VM -Name $machine.ResourceName).Uptime.TotalSeconds
            Write-Debug -Message "Uptime machine '$($machine.ResourceName)'=$currentMachineUptime, Saved uptime=$($machine.uptime)"
            if ($machine.Uptime -ne 0 -and $currentMachineUptime -lt $machine.Uptime)
            {
                Write-PSFMessage -Message "Machine '$machine' is now stopped"
                $machine.Uptime = 0
            }
        }

        Start-Sleep -Seconds 2

        if ($MonitorJob)
        {
            foreach ($job in $MonitorJob)
            {
                if ($job.State -eq 'Failed')
                {
                    $result = $job | Receive-Job -ErrorVariable jobError

                    $criticalError = $jobError | Where-Object { $_.Exception.Message -like 'AL_CRITICAL*' }
                    if ($criticalError) { throw $criticalError.Exception }

                    $nonCriticalErrors = $jobError | Where-Object { $_.Exception.Message -like 'AL_ERROR*' }
                    foreach ($nonCriticalError in $nonCriticalErrors)
                    {
                        Write-PSFMessage "There was a non-critical error in job $($job.ID) '$($job.Name)' with the message: '($nonCriticalError.Exception.Message)'"
                    }
                }
            }
        }
    }
    until (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)

    if (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0)
    {
        Write-PSFMessage -Message "All machines have stopped: ($($machines.name -join ', '))"
    }

    if ((Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)
    {
        foreach ($Computer in $ComputerName)
        {
            if ($machineInfo.($Computer) -gt 0)
            {
                Write-Error -Message "Timeout while waiting for computer '$computer' to restart." -TargetObject $computer
            }
        }
    }

    $remainingMinutes = $TimeoutInMinutes - ((Get-Date) - $start).TotalMinutes
    Wait-LabVM -ComputerName $ComputerName -ProgressIndicator $ProgressIndicator -TimeoutInMinutes $remainingMinutes -NoNewLine:$NoNewLine

    if ($delayedStart)
    {
        Start-LabVM -ComputerName $delayedStart -NoNewline:$NoNewLine
    }

    Write-ProgressIndicatorEnd

    Write-LogFunctionExit
}
#endregion Wait-LWHypervVMRestart

#region Start-LWHypervVM
function Start-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0,

        [int]$PreDelaySeconds = 0,

        [int]$PostDelaySeconds = 0,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    if ($PreDelay) {
        $job = Start-Job -Name 'Start-LWHypervVM - Pre Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PreDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    foreach ($Name in $(Get-LabVM -ComputerName $ComputerName -IncludeLinux))
    {
        $machine = Get-LabVM -ComputerName $Name -IncludeLinux

        $machineMetadata = Get-LWHypervVMDescription -ComputerName $Name.ResourceName

        try
        {
            Start-VM -Name $Name.ResourceName -ErrorAction Stop

            if ($machine.NetworkAdapters.Count -gt 1 -and
            ($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected) -ne [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected)
            {
                Repair-LWHypervNetworkConfig -ComputerName $Name
                $machineMetadata.InitState = [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected
                Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $Name.ResourceName
            }
        }
        catch
        {
            $ex = New-Object System.Exception("Could not start Hyper-V machine '$ComputerName': $($_.Exception.Message)", $_.Exception)
            throw $ex
        }

        if ($Name.OperatingSystemType -eq 'Linux')
        {
            Write-PSFMessage -Message "Skipping the wait period for $Name as it is a Linux system"
            continue
        }

        if ($DelayBetweenComputers -and $Name -ne $ComputerName[-1])
        {
            $job = Start-Job -Name 'Start-LWHypervVM - DelayBetweenComputers' -ScriptBlock { Start-Sleep -Seconds $Using:DelayBetweenComputers }
            Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
        }
    }

    if ($PostDelay)
    {
        $job = Start-Job -Name 'Start-LWHypervVM - Post Delay' -ScriptBlock { Start-Sleep -Seconds $Using:PostDelaySeconds }
        Wait-LWLabJob -Job $job -NoNewLine:$NoNewLine -ProgressIndicator $ProgressIndicator -Timeout 15 -NoDisplay
    }

    Write-LogFunctionExit
}
#endregion Start-LWHypervVM

#region Stop-LWHypervVM
function Stop-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [switch]$ShutdownFromOperatingSystem = $true
    )

    Write-LogFunctionEntry

    $start = Get-Date

    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = (Get-LabVM -ComputerName $ComputerName -IncludeLinux).Where({ $_.OperatingSystemType -eq 'Linux' }, 'Split')

        if ($windows)
        {
            $jobs += Invoke-LabCommand -ComputerName $windows -NoDisplay -AsJob -PassThru -ScriptBlock {
                Stop-Computer -Force -ErrorAction Stop
            }
        }

        if ($linux)
        {
            $jobs += Invoke-LabCommand -UseLocalCredential -ComputerName $linux -NoDisplay -AsJob -PassThru -ScriptBlock {
                #Sleep as background process so that job does not fail.
                [void] (Start-Job -ScriptBlock {
                        Start-Sleep -Seconds 5
                        shutdown -P now
                })
            }
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Hyper-V VM(s): '$($failedJobs.Location)'" -Type Error
        }

        $stopFailures = foreach ($failedJob in $failedJobs)
        {
            if (Get-LabVm -ComputerName $failedJob.Location -IncludeLinux)
            {
                $failedJob.Location
            }
        }

        if ($stopFailures)
        {
            Write-ScreenInfo -Message "Force-stopping VMs: $($stopFailures -join ',')"
            Stop-VM -Name $stopFailures -Force
        }
    }
    else
    {
        $jobs = @()
        foreach ($name in (Get-LabVm -ComputerName $ComputerName -IncludeLinux).ResourceName)
        {
            $job = Start-Job -Name "AL_Shutdown_$name" -ScriptBlock {
                try
                {
                    Stop-VM -Name $using:name -Force -ErrorAction Stop
                }
                catch
                {
                    Write-Error -Exception $_.Exception -TargetObject $using:name
                }
            }
            $job | Add-Member -Name ComputerName -MemberType NoteProperty -Value $name
            $jobs += $job
        }
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -NoNewLine:$NoNewLine -NoDisplay

        #receive the result of all finished jobs. The result should be null except if an error occured. The error will be returned to the caller
        $jobs | Where-Object State -eq completed | Receive-Job
    }

    Write-LogFunctionExit
}
#endregion Stop-LWHypervVM

#region Save-LWHypervVM
function Save-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    $runspaceScript = {
        param
        (
            [string]$Name
        )
        Write-LogFunctionEntry
        Save-VM -Name $Name
        Write-LogFunctionExit
    }

    $pool = New-RunspacePool -ThrottleLimit 50

    $jobs = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $runspaceScript -Argument $Name
    }

    [void] ($jobs | Wait-RunspaceJob)

    $pool | Remove-RunspacePool
}
#endregion Save-LWHypervVM

#region Checkpoint-LWHypervVM
function Checkpoint-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Write-LogFunctionEntry

    $step1 = {
        param ($Name)
        if ((Get-VM -Name $Name -ErrorAction SilentlyContinue).State -eq 'Running' -and -not (Get-VMSnapshot -VMName $Name -Name $SnapshotName -ErrorAction SilentlyContinue))
        {
            Suspend-VM -Name $Name -ErrorAction SilentlyContinue
            Save-VM -Name $Name -ErrorAction SilentlyContinue

            Write-Verbose -Message "'$Name' was running"
            $Name
        }
    }
    $step2 = {
        param ($Name)
        if (-not (Get-VMSnapshot -VMName $Name -Name $SnapshotName -ErrorAction SilentlyContinue))
        {
            Checkpoint-VM -Name $Name -SnapshotName $SnapshotName
        }
        else
        {
            Write-Error "A snapshot with the name '$SnapshotName' already exists for machine '$Name'"
        }
    }
    $step3 = {
        param ($Name, $RunningMachines)
        if ($Name -in $RunningMachines)
        {
            Write-Verbose -Message "Machine '$Name' was running, starting it."
            Start-VM -Name $Name -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Verbose -Message "Machine '$Name' was NOT running."
        }
    }

    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable -Name SnapshotName)

    $jobsStep1 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step1 -Argument $Name
    }

    $runningMachines = $jobsStep1 | Receive-RunspaceJob

    $jobsStep2 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step2 -Argument $Name
    }

    [void] ($jobsStep2 | Wait-RunspaceJob)

    $jobsStep3 = foreach ($Name in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -ScriptBlock $step3 -Argument $Name, $runningMachines
    }

    [void] ($jobsStep3 | Wait-RunspaceJob)

    $pool | Remove-RunspacePool

    Write-LogFunctionExit
}
#endregion Checkpoint-LWVM

#region Remove-LWHypervVMSnapshot
function Remove-LWHypervVMSnapshot
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [Parameter(Mandatory, ParameterSetName = 'AllSnapshots')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [string]$SnapshotName,

        [Parameter(ParameterSetName = 'AllSnapshots')]
        [switch]$All
    )

    Write-LogFunctionEntry
    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable -Name SnapshotName,All -ErrorAction SilentlyContinue)

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param ($n)
            if ($SnapshotName)
            {
                $snapshot = Get-VMSnapshot -VMName $n | Where-Object -FilterScript {
                    $_.Name -eq $SnapshotName
                }
            }
            else
            {
                $snapshot = Get-VMSnapshot -VMName $n
            }

            if (-not $snapshot)
            {
                Write-Error -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
            }
            else
            {
                Remove-VMSnapshot -VMName $n -Name $snapshot.Name -IncludeAllChildSnapshots -ErrorAction SilentlyContinue
            }
        }
    }

    $jobs | Receive-RunspaceJob

    $pool | Remove-RunspacePool

    Write-LogFunctionExit
}
#endregion Remove-LWHypervVMSnapshot

#region Restore-LWHypervVMSnapshot
function Restore-LWHypervVMSnapshot
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Write-LogFunctionEntry

    $pool = New-RunspacePool -ThrottleLimit 20 -Variable (Get-Variable SnapshotName)

    Write-PSFMessage -Message 'Remembering all running machines'
    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param ($n)

            if ((Get-VM -Name $n -ErrorAction SilentlyContinue).State -eq 'Running')
            {
                Write-Verbose -Message "    '$n' was running"
                $n
            }
        }
    }

    $runningMachines = $jobs | Receive-RunspaceJob

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param ($n)
            Suspend-VM -Name $n -ErrorAction SilentlyContinue
            Save-VM -Name $n -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
        }
    }

    $jobs | Wait-RunspaceJob

    $jobs = foreach  ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n -ScriptBlock {
            param (
                [string]$n
            )

            $snapshot = Get-VMSnapshot -VMName $n | Where-Object Name -eq $SnapshotName

            if (-not $snapshot)
            {
                Write-Error -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
            }
            else
            {
                Restore-VMSnapshot -VMName $n -Name $SnapshotName -Confirm:$false
                Set-VM -Name $n -Notes (Get-VMSnapshot -VMName $n -Name $SnapshotName).Notes

                Start-Sleep -Seconds 5
            }
        }
    }

    $result = $jobs | Wait-RunspaceJob -PassThru
    if ($result.Shell.HadErrors)
    {
        foreach ($exception in $result.Shell.Streams.Error.Exception)
        {
            Write-Error -Exception $exception
        }
    }

    Write-PSFMessage -Message "Restore finished, starting the machines that were running previously ($($runningMachines.Count))"

    $jobs = foreach ($n in $ComputerName)
    {
        Start-RunspaceJob -RunspacePool $pool -Argument $n,$runningMachines -ScriptBlock {
            param ($n, [string[]]$runningMachines)
            if ($n -in $runningMachines)
            {
                Write-Verbose -Message "Machine '$n' was running, starting it."
                Start-VM -Name $n -ErrorAction SilentlyContinue
            }
            else
            {
                Write-Verbose -Message "Machine '$n' was NOT running."
            }
        }
    }

    [void] ($jobs | Wait-RunspaceJob)

    $pool | Remove-RunspacePool
    Write-LogFunctionExit
}
#endregion Restore-LWHypervVMSnapshot

#region Get-LWHypervVMSnapshot
function Get-LWHypervVMSnapshot
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param
    (
        [string[]]$VMName,

        [string]$Name
    )

    Write-LogFunctionEntry

    (Hyper-V\Get-VMSnapshot @PSBoundParameters).ForEach({
            [AutomatedLab.Snapshot]::new($_.Name, $_.VMName, $_.CreationTime)
    })

    Write-LogFunctionExit
}
#endregion

#region Get-LWHypervVMStatus
function Get-LWHypervVMStatus
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $result = @{ }
    $vms = Get-VM -Name $ComputerName
    $vmTable = @{ }
    Get-LabVm -IncludeLinux | Where-Object FriendlyName -in $ComputerName | ForEach-Object {$vmTable[$_.FriendlyName] = $_.Name}

    foreach ($vm in $vms)
    {
        $vmName = if ($vmTable[$vm.Name]) {$vmTable[$vm.Name]} else {$vm.Name}
        if ($vm.State -eq 'Running')
        {
            $result.Add($vmName, 'Started')
        }
        elseif ($vm.State -eq 'Off')
        {
            $result.Add($vmName, 'Stopped')
        }
        else
        {
            $result.Add($vmName, 'Unknown')
        }
    }

    $result

    Write-LogFunctionExit
}
#endregion Get-LWHypervVMStatus

#region Enable-LWHypervVMRemoting
function Enable-LWHypervVMRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabVM -ComputerName $ComputerName

    $script = {
        param ($DomainName, $UserName, $Password)

        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

        Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultUserName -Value $UserName -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultPassword -Value $Password -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $DomainName -ErrorAction SilentlyContinue

        Enable-WSManCredSSP -Role Server -Force | Out-Null
    }

    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))
        try
        {
            Invoke-LabCommand -ComputerName $machine -ActivityName SetLabVMRemoting -ScriptBlock $script -DoNotUseCredSsp -NoDisplay  `
            -ArgumentList $machine.DomainName, $cred.UserName, $cred.GetNetworkCredential().Password -ErrorAction Stop
        }
        catch
        {
            Connect-WSMan -ComputerName $machine -Credential $cred
            Set-Item -Path "WSMan:\$machine\Service\Auth\CredSSP" -Value $true
            Disconnect-WSMan -ComputerName $machine
        }
    }
}
#endregion Enable-LWHypervVMRemoting

#region Mount-LWIsoImage
function Mount-LWIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]$IsoPath,

        [switch]$PassThru
    )

    if (-not (Test-Path -Path $IsoPath -PathType Leaf))
    {
        Write-Error "The path '$IsoPath' could not be found or is pointing to a folder"
        return
    }

    $machines = Get-LabVM -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        Write-PSFMessage -Message "Adding DVD drive '$IsoPath' to machine '$machine'"
        $start = (Get-Date)
        $done = $false
        $delayBeforeCheck = 5, 10, 15, 30, 45, 60
        $delayIndex = 0

        $dvdDrivesBefore = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
        } -PassThru -NoDisplay

        #this is required as Compare-Object cannot work with a null object
        if (-not $dvdDrivesBefore) { $dvdDrivesBefore = @() }

        while ((-not $done) -and ($delayIndex -le $delayBeforeCheck.Length))
        {
            try
            {
                if ($machine.OperatingSystem.Version -ge '6.2')
                {
                    $drive = Add-VMDvdDrive -VMName $machine.ResourceName -Path $IsoPath -ErrorAction Stop -Passthru
                }
                else
                {
                    if (-not (Get-VMDvdDrive -VMName $machine.ResourceName))
                    {
                        throw "No DVD drive exist for machine '$machine'. Machine is generation 1 and DVD drive needs to be crate in advance (during creation of the machine). Cannot continue."
                    }
                    $drive = Set-VMDvdDrive -VMName $machine.ResourceName -Path $IsoPath -ErrorAction Stop -Passthru
                }

                Start-Sleep -Seconds $delayBeforeCheck[$delayIndex]

                if ((Get-VMDvdDrive -VMName $machine.ResourceName).Path -contains $IsoPath)
                {
                    $done = $true
                }
                else
                {
                    Write-ScreenInfo -Message "DVD drive '$IsoPath' was NOT successfully added to machine '$machine'. Retrying." -Type Error
                    $delayIndex++
                }
            }
            catch
            {
                Write-ScreenInfo -Message "Could not add DVD drive '$IsoPath' to machine '$machine'. Retrying." -Type Warning
                Start-Sleep -Seconds $delayBeforeCheck[$delayIndex]
            }
        }

        $dvdDrivesAfter = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType = 5 AND FileSystem LIKE "%"' | Select-Object -ExpandProperty DeviceID
        } -PassThru -NoDisplay

        $driveLetter = (Compare-Object -ReferenceObject $dvdDrivesBefore -DifferenceObject $dvdDrivesAfter).InputObject
        $drive | Add-Member -Name DriveLetter -MemberType NoteProperty -Value $driveLetter

        if ($PassThru) { $drive }

        if (-not $done)
        {
            throw "Could not add DVD drive '$IsoPath' to machine '$machine' after repeated attempts."
        }
    }
}
#endregion Mount-LWIsoImage

#region Dismount-LWIsoImage
function Dismount-LWIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabVM -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        if ($machine.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            Write-PSFMessage -Message "Removing DVD drive for machine '$machine'"
            Get-VMDvdDrive -VMName $machine.ResourceName | Remove-VMDvdDrive
        }
        else
        {
            Write-PSFMessage -Message "Setting DVD drive for machine '$machine' to null"
            Get-VMDvdDrive -VMName $machine.ResourceName | Set-VMDvdDrive -Path $null
        }
    }
}
#endregion Dismount-LWIsoImage

#region Repair-LWHypervNetworkConfig
function Repair-LWHypervNetworkConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $machine = Get-LabVM -ComputerName $ComputerName

    if (-not $machine) { return } # No fixing this on a Linux VM

    Wait-LabVM -ComputerName $machine -NoNewLine

    #remoting does serialization with a depth of 1. Here we need more
    $machineStream = [System.Management.Automation.PSSerializer]::Serialize($machine, 4)

    Invoke-LabCommand -ComputerName $machine -ActivityName "Network config on '$machine' (renaming and ordering)" -ScriptBlock {
        $machine = [System.Management.Automation.PSSerializer]::Deserialize($machineStream)

        Write-Verbose "Renaming network adapters"
        #rename the adapters as defined in the lab

        $newNames = @()
        foreach ($adapterInfo in $machine.NetworkAdapters)
        {
            $newName = Add-StringIncrement -String $adapterInfo.VirtualSwitch.ResourceName
            while ($newName -in $newNames)
            {
                $newName = Add-StringIncrement -String $newName
            }
            $newNames += $newName
            if (-not [string]::IsNullOrEmpty($adapterInfo.VirtualSwitch.FriendlyName))
            {
                $adapterInfo.VirtualSwitch.FriendlyName = $newName
            }
            else
            {
                $adapterInfo.VirtualSwitch.Name = $newName
            }

            if ($machine.OperatingSystem.Version.Major -lt 6 -and $machine.OperatingSystem.Version.Minor -lt 2)
            {
                $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join ':'
                $filter = 'MACAddress = "{0}"' -f $mac
                Write-Verbose "Looking for network adapter with using filter '$filter'"
                $adapter = Get-CimInstance -Class Win32_NetworkAdapter -Filter $filter

                Write-Verbose "Renaming adapter '$($adapter.NetConnectionID)' -> '$newName'"
                $adapter.NetConnectionID = $newName
                $adapter.Put()
            }
            else
            {
                $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join '-'
                Write-Verbose "Renaming adapter '$($adapter.NetConnectionID)' -> '$newName'"
                Get-NetAdapter | Where-Object MacAddress -eq $mac | Rename-NetAdapter -NewName $newName
            }
        }

        #There is no need to change the network binding order in Windows 10 or 2016
        #Adjusting the Network Protocol Bindings in Windows 10 https://blogs.technet.microsoft.com/networking/2015/08/14/adjusting-the-network-protocol-bindings-in-windows-10/
        if ([System.Environment]::OSVersion.Version.Major -lt 10)
        {
            $retries = $machine.NetworkAdapters.Count * $machine.NetworkAdapters.Count * 2
            $i = 0

            $sortedAdapters = New-Object System.Collections.ArrayList
            $sortedAdapters.AddRange(@($machine.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType.Value -ne 'Internal' }))
            $sortedAdapters.AddRange(@($machine.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType.Value -eq 'Internal' }))

            Write-Verbose "Setting the network order"
            [array]::Reverse($machine.NetworkAdapters)
            foreach ($adapterInfo in $sortedAdapters)
            {
                Write-Verbose "Setting the order for adapter '$($adapterInfo.VirtualSwitch.ResourceName)'"
                do {
                    nvspbind.exe /+ $adapterInfo.VirtualSwitch.ResourceName ms_tcpip | Out-File -FilePath c:\nvspbind.log -Append
                    $i++

                    if ($i -gt $retries) { return }
                }  until ($LASTEXITCODE -eq 14)
            }
        }

    } -Function (Get-Command -Name Get-StringSection, Add-StringIncrement) -Variable (Get-Variable -Name machineStream) -NoDisplay

    foreach ($adapterInfo in $machine.NetworkAdapters)
    {
        $vmAdapter = Get-VMNetworkAdapter -VMName $machine.ResourceName -Name $adapterInfo.VirtualSwitch.ResourceName

        if ($adapterInfo.VirtualSwitch.ResourceName -ne $vmAdapter.SwitchName)
        {
            $vmAdapter | Connect-VMNetworkAdapter -SwitchName $adapterInfo.VirtualSwitch.ResourceName
        }
    }

    Write-LogFunctionExit
}
#endregion Repair-LWHypervNetworkConfig

#region Get / Set-LWHypervVMDescription
function Set-LWHypervVMDescription
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$Hashtable,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String,String
    $disctionary = New-Object $type

    foreach ($kvp in $Hashtable.GetEnumerator())
    {
        $disctionary.Add($kvp.Key, $kvp.Value)
    }

    $notes = $disctionary.ExportToString()

    Set-VM -Name $ComputerName -Notes $notes

    Write-LogFunctionExit
}

function Get-LWHypervVMDescription
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $vm = Get-VM -Name $ComputerName -ErrorAction SilentlyContinue
    if (-not $vm)
    {
        return
    }

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T String,String

    try
    {
        $importMethodInfo = $type.GetMethod('ImportFromString', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $dictionary = $importMethodInfo.Invoke($null, $vm.Notes)
        $dictionary
    }
    catch
    {
        Write-ScreenInfo -Message "The notes field of the virtual machine '$ComputerName' could not be read as XML" -Type Warning
    }

    Write-LogFunctionExit
}
#endregion Get / Set-LWHypervVMDescription
