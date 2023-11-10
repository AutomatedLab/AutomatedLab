function New-LWHypervVM
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $PSBoundParameters.Add('ProgressIndicator', 1) #enables progress indicator
    if ($Machine.SkipDeployment) { return }

    Write-LogFunctionEntry

    $script:lab = Get-Lab

    if (Get-LWHypervVM -Name $Machine.ResourceName -ErrorAction SilentlyContinue)
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "The machine '$Machine' does already exist" -Type Warning
        return $false
    }

    if ($PSDefaultParameterValues.ContainsKey('*:IsKickstart')) { $PSDefaultParameterValues.Remove('*:IsKickstart') }
    if ($PSDefaultParameterValues.ContainsKey('*:IsAutoYast')) { $PSDefaultParameterValues.Remove('*:IsAutoYast') }
    if ($PSDefaultParameterValues.ContainsKey('*:IsCloudInit')) { $PSDefaultParameterValues.Remove('*:IsCloudInit') }

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
        $Machine.ProductKey = $Machine.OperatingSystem.ProductKey
    }

    Import-UnattendedContent -Content $Machine.UnattendedXmlContent
    #endregion

    #region network adapter settings
    $macAddressPrefix = Get-LabConfigurationItem -Name MacAddressPrefix
    $macAddressesInUse = @(Get-LWHypervVM | Get-VMNetworkAdapter | Select-Object -ExpandProperty MacAddress)
    $macAddressesInUse += (Get-LabVm -IncludeLinux).NetworkAdapters.MacAddress

    $macIdx = 0
    $prefixlength = 12 - $macAddressPrefix.Length
    while ("$macAddressPrefix{0:X$prefixLength}" -f $macIdx -in $macAddressesInUse) { $macIdx++ }

    $type = Get-Type -GenericType AutomatedLab.ListXmlStore -T AutomatedLab.NetworkAdapter
    $adapters = New-Object $type
    $Machine.NetworkAdapters | ForEach-Object {$adapters.Add($_)}

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

        $prefixlength = 12 - $macAddressPrefix.Length
        $mac = "$macAddressPrefix{0:X$prefixLength}" -f $macIdx++

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

        if (-not $Machine.IsDomainJoined -and (-not $adapter.ConnectionSpecificDNSSuffix))
        {
            $rootDomainName = Get-LabVM -Role RootDC | Select-Object -First 1 | Select-Object -ExpandProperty DomainName
            $ipSettings.Add('DnsDomain', $rootDomainName)
        }

        if ($adapter.ConnectionSpecificDNSSuffix)
        {
            $ipSettings.Add('DnsDomain', $adapter.ConnectionSpecificDNSSuffix)
        }
        $ipSettings.Add('UseDomainNameDevolution', (([string]($adapter.AppendParentSuffixes)) = 'true'))
        if ($adapter.AppendDNSSuffixes)
        {
            $ipSettings.Add('DNSSuffixSearchOrder', $adapter.AppendDNSSuffixes -join ',')
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
            'Default'  { $ipSettings.Add('NetBIOSOptions', '0') }
            'Enabled'  { $ipSettings.Add('NetBIOSOptions', '1') }
            'Disabled' { $ipSettings.Add('NetBIOSOptions', '2') }
        }

        Add-UnattendedNetworkAdapter @ipSettings
    }

    $Machine.NetworkAdapters = $adapters

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
    
    if ($Machine.OperatingSystemType -eq 'Linux' -and -not [string]::IsNullOrEmpty($Machine.SshPublicKey))
    {
        Add-UnattendedSynchronousCommand -Command "restorecon -R /root/.ssh/" -Description 'Restore SELinux context'
        Add-UnattendedSynchronousCommand -Command "restorecon -R /$($Machine.InstallationUser.UserName)/.ssh/" -Description 'Restore SELinux context'
        Add-UnattendedSynchronousCommand -Command "sed -i 's|[#]*PubkeyAuthentication yes|PubkeyAuthentication yes|g' /etc/ssh/sshd_config" -Description 'PowerShell is so much better.'
        Add-UnattendedSynchronousCommand -Command "sed -i 's|[#]*PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config" -Description 'PowerShell is so much better.'
        Add-UnattendedSynchronousCommand -Command "sed -i 's|[#]*GSSAPIAuthentication yes|GSSAPIAuthentication yes|g' /etc/ssh/sshd_config" -Description 'PowerShell is so much better.'
        Add-UnattendedSynchronousCommand -Command "chmod 700 /home/$($Machine.InstallationUser.UserName)/.ssh && chmod 600 /home/$($Machine.InstallationUser.UserName)/.ssh/authorized_keys" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "chown -R $($Machine.InstallationUser.UserName):$($Machine.InstallationUser.UserName) /home/$($Machine.InstallationUser.UserName)/.ssh" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "chown -R root:root /root/.ssh" -Description 'SSH'        
        Add-UnattendedSynchronousCommand -Command "echo `"$($Machine.SshPublicKey)`" > /home/$($Machine.InstallationUser.UserName)/.ssh/authorized_keys" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "echo `"$($Machine.SshPublicKey)`" > /root/.ssh/authorized_keys" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "mkdir -p /home/$($Machine.InstallationUser.UserName)/.ssh" -Description 'SSH'
        Add-UnattendedSynchronousCommand -Command "mkdir -p /root/.ssh" -Description 'SSH'
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
            $domain = $lab.Domains | Where-Object Name -eq $Machine.DomainName

            $parameters = @{
                DomainName = $Machine.DomainName
                Username = $domain.Administrator.UserName
                Password = $domain.Administrator.Password
            }
            if ($Machine.OrganizationalUnit) {
                $parameters['OrganizationalUnit'] = $machine.OrganizationalUnit
            }

            Set-UnattendedDomain @parameters

            if ($Machine.OperatingSystemType -eq 'Linux')
            {
                $sudoParam = @{
                    Command = "sed -i '/^%wheel.*/a %$($Machine.DomainName.ToUpper())\\\\domain\\ admins ALL=(ALL) NOPASSWD: ALL' /etc/sudoers"
                    Description = 'Enable domain admin as sudoer without password'
                }

                Add-UnattendedSynchronousCommand @sudoParam

                if (-not [string]::IsNullOrEmpty($Machine.SshPublicKey))
                {
                    Add-UnattendedSynchronousCommand -Command "restorecon -R /$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh/" -Description 'Restore SELinux context'
                    Add-UnattendedSynchronousCommand -Command "echo `"$($Machine.SshPublicKey)`" > /home/$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh/authorized_keys" -Description 'SSH'
                    Add-UnattendedSynchronousCommand -Command "chmod 700 /home/$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh && chmod 600 /home/$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh/authorized_keys" -Description 'SSH'
                    Add-UnattendedSynchronousCommand -Command "chown -R $($Machine.InstallationUser.UserName)@$($Machine.DomainName):$($Machine.InstallationUser.UserName)@$($Machine.DomainName) /home/$($Machine.InstallationUser.UserName)@$($Machine.DomainName)/.ssh" -Description 'SSH'
                    Add-UnattendedSynchronousCommand -Command "mkdir -p /home/$($domain.Administrator.UserName)@$($Machine.DomainName)/.ssh" -Description 'SSH'
                }
            }
        }
    }

    #set the Generation for the VM depending on SupportGen2VMs, host OS version and VM OS version
    $hostOsVersion = [System.Environment]::OSVersion.Version

    $generation = if (Get-LabConfigurationItem -Name SupportGen2VMs)
    {
        if ($Machine.VmGeneration -ne 1 -and $hostOsVersion -ge [System.Version]6.3 -and $Machine.Gen2VmSupported)
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
        if ($Machine.LinuxType -in 'RedHat', 'Ubuntu')
        {
            $size = 100MB
        }
        $label = if ($Machine.LinuxType -eq 'RedHat') { 'OEMDRV' } else { 'CIDATA' }
        $unattendPartition = $mountedOsDisk | New-Partition -Size $size

        # Use a small FAT32 partition to hold AutoYAST and Kickstart configuration
        $diskpartCmd = "@
            select disk $($mountedOsDisk.DiskNumber)
            select partition $($unattendPartition.PartitionNumber)
            format quick fs=fat32 label=$label
            exit
        @"
        $diskpartCmd | diskpart.exe | Out-Null

        $unattendPartition | Set-Partition -NewDriveLetter $nextDriveLetter
        $unattendPartition = $unattendPartition | Get-Partition
        $drive = [System.IO.DriveInfo][string]$unattendPartition.DriveLetter

        if ( $machine.OperatingSystemType -eq 'Linux' -and $machine.LinuxPackageGroup )
        {
            Set-UnattendedPackage -Package $machine.LinuxPackageGroup
        }
        elseif ($machine.LinuxType -eq 'RedHat')
        {
            Set-UnattendedPackage -Package '@^server-product-environment'
        }

        # Copy Unattend-Stuff here
        if ($Machine.LinuxType -eq 'RedHat')
        {
            Export-UnattendedFile -Path (Join-Path -Path $drive.RootDirectory -ChildPath ks.cfg)
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

            ($grubFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 autoyast=device:///autoinst.xml" | Set-Content -Path $grubFile.FullName
            ($isolinuxFile | Get-Content -Raw) -replace "splash=silent", "splash=silent textmode=1 autoyast=device:///autoinst.xml" | Set-Content -Path $isolinuxFile.FullName
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
        $referenceDiskPath = if ($Machine.ReferenceDiskPath) { $Machine.ReferenceDiskPath } else { $Machine.OperatingSystem.BaseDiskPath }
        $systemDisk = New-VHD -Path $path -Differencing -ParentPath $referenceDiskPath -ErrorAction Stop
        Write-PSFMessage "`tcreated differencing disk '$($systemDisk.Path)' pointing to '$ReferenceVhdxPath'"

        $mountedOsDisk = Mount-VHD -Path $path -Passthru
        try
        {
            $drive = $mountedosdisk | get-disk | Get-Partition | Get-Volume  | Where {$_.DriveLetter -and $_.FileSystemLabel -eq 'System'}

            $paths = [Collections.ArrayList]::new()
            $alcommon = Get-Module -Name AutomatedLab.Common
            $null = $paths.Add((Split-Path -Path $alcommon.ModuleBase -Parent))
            $null = foreach ($req in $alCommon.RequiredModules.Name)
            {
                $paths.Add((Split-Path -Path (Get-Module -Name $req -ListAvailable)[0].ModuleBase -Parent))
            }

            Copy-Item -Path $paths -Destination "$($drive.DriveLetter):\Program Files\WindowsPowerShell\Modules" -Recurse


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

    $vmParameter = @{
        Name = $Machine.ResourceName
        MemoryStartupBytes = ($Machine.Memory)
        VHDPath = $systemDisk.Path
        Path = $VmPath
        Generation = $generation
        ErrorAction = 'Stop'
    }

    $vm = Hyper-V\New-VM @vmParameter

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

        $vmFirmwareParameters = @{}

        if ($Machine.HypervProperties.EnableSecureBoot)
        {
            $vmFirmwareParameters.EnableSecureBoot = 'On'
            $vmFirmwareParameters.SecureBootTemplate = $secureBootTemplate
        }
        else
        {
            $vmFirmwareParameters.EnableSecureBoot = 'Off'
        }

        $vm | Set-VMFirmware @vmFirmwareParameters

        if ($Machine.HyperVProperties.EnableTpm -match '1|true|yes')
        {
            $vm | Set-VMKeyProtector -NewLocalKeyProtector
            $vm | Enable-VMTPM
        }
    }

    #remove the unconnected default network adapter
    $vm | Remove-VMNetworkAdapter
    foreach ($adapter in $adapters)
    {
        #bind all network adapters to their designated switches, Repair-LWHypervNetworkConfig will change the binding order if necessary
        $parameters = @{
            Name             = $adapter.VirtualSwitch.ResourceName
            SwitchName       = $adapter.VirtualSwitch.ResourceName
            StaticMacAddress = $adapter.MacAddress
            VMName           = $vm.Name
            PassThru         = $true
        }

        if (-not (Get-LabConfigurationItem -Name DisableDeviceNaming -Default $false) -and (Get-Command Add-VMNetworkAdapter).Parameters.Values.Name -contains 'DeviceNaming' -and $vm.Generation -eq 2 -and $Machine.OperatingSystem.Version -ge 10.0)
        {
            $parameters['DeviceNaming'] = 'On'
        }

        $newAdapter = Add-VMNetworkAdapter @parameters

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
    $vm | Hyper-V\Set-VM -AutomaticStartAction $automaticStartAction -AutomaticStartDelay $automaticStartDelay -AutomaticStopAction $automaticStopAction

    Write-ProgressIndicator

    if ( $Machine.OperatingSystemType -eq 'Linux' -and $Machine.LinuxType -in 'RedHat','Ubuntu')
    {
        $dvd = $vm | Add-VMDvdDrive -Path $Machine.OperatingSystem.IsoPath -Passthru
        $vm | Set-VMFirmware -FirstBootDevice $dvd
    }

    if ( $Machine.OperatingSystemType -eq 'Windows')
    {
        [void](Mount-DiskImage -ImagePath $path)
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
        Write-PSFMessage "`tDisk mounted to drive $VhdVolume"

        #Get-PSDrive needs to be called to update the PowerShell drive list
        Get-PSDrive | Out-Null

        #copy AL tools to lab machine and optionally the tools folder
        $drive = New-PSDrive -Name $VhdVolume[0] -PSProvider FileSystem -Root $VhdVolume

        Write-PSFMessage 'Copying AL tools to VHD...'
        $tempPath = "$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetRandomFileName())"
        New-Item -ItemType Directory -Path $tempPath | Out-Null
        Copy-Item -Path "$((Get-Module -Name AutomatedLabCore)[0].ModuleBase)\Tools\HyperV\*" -Destination $tempPath -Recurse
        foreach ($file in (Get-ChildItem -Path $tempPath -Recurse -File))
        {
            # Why???
            if ($PSEdition -eq 'Desktop')
            {
                $file.Decrypt()
            }
        }

        Copy-Item -Path "$tempPath\*" -Destination "$vhdVolume\Windows" -Recurse

        Remove-Item -Path $tempPath -Recurse -ErrorAction SilentlyContinue

        Write-PSFMessage '...done'

        

    if ($Machine.OperatingSystemType -eq 'Windows' -and -not [string]::IsNullOrEmpty($Machine.SshPublicKey))
    {
        Add-UnattendedSynchronousCommand -Command 'PowerShell -File "C:\Program Files\OpenSSH-Win64\install-sshd.ps1"' -Description 'Configure SSH'
        Add-UnattendedSynchronousCommand -Command 'PowerShell -Command "Set-Service -Name sshd -StartupType Automatic"' -Description 'Enable SSH'
        Add-UnattendedSynchronousCommand -Command 'PowerShell -Command "Restart-Service -Name sshd"' -Description 'Restart SSH'

        Write-PSFMessage 'Copying PowerShell 7 and setting up SSH'
        $release = try {Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/powershell/releases/latest' -UseBasicParsing -ErrorAction Stop } catch {}
        $uri = ($release.assets | Where-Object name -like '*-win-x64.zip').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/PowerShell-7.2.6-win-x64.zip'
        }
        $psArchive = Get-LabInternetFile -Uri $uri -Path "$labSources/SoftwarePackages/PS7.zip"

        
        $release = try {Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/win32-openssh/releases/latest' -UseBasicParsing -ErrorAction Stop } catch {}
        $uri = ($release.assets | Where-Object name -like '*-win64.zip').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.9.1.0p1-Beta/OpenSSH-Win64.zip'
        }
        $sshArchive = Get-LabInternetFile -Uri $uri -Path "$labSources/SoftwarePackages/ssh.zip"

        $null = New-Item -ItemType Directory -Force -Path (Join-Path -Path $vhdVolume -ChildPath 'Program Files\PowerShell\7')
        Expand-Archive -Path "$labSources/SoftwarePackages/PS7.zip" -DestinationPath (Join-Path -Path $vhdVolume -ChildPath 'Program Files\PowerShell\7')
        Expand-Archive -Path "$labSources/SoftwarePackages/ssh.zip" -DestinationPath (Join-Path -Path $vhdVolume -ChildPath 'Program Files')

        $null = New-Item -ItemType File -Path (Join-Path -Path $vhdVolume -ChildPath '\AL\SSH\keys'),(Join-Path -Path $vhdVolume -ChildPath 'ProgramData\ssh\sshd_config') -Force
        
        $Machine.SshPublicKey | Add-Content -Path (Join-Path -Path $vhdVolume -ChildPath '\AL\SSH\keys')
        
        $sshdConfig = @"
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
GSSAPIAuthentication yes
AllowGroups Users Administrators
AuthorizedKeysFile c:/al/ssh/keys
Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo
"@
            $sshdConfig | Set-Content -Path (Join-Path -Path $vhdVolume -ChildPath 'ProgramData\ssh\sshd_config')
            Write-PSFMessage 'Done'
    }

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
$pattern = 'Disk (?<DiskNumber>\d{1,3}) \s+(?<State>Online|Offline)\s+(?<Size>\d+) (KB|MB|GB|TB)\s+(?<Free>\d+) (B|KB|MB|GB|TB)'
foreach ($line in $disks)
{
    if ($line -match $pattern)
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
    if ($volume.Label -notmatch '(?<Label>[-_\w\d]+)_AL_(?<DriveLetter>[A-Z])')
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

            $subdir = if ($setting.Key -match 'MaxEnvelope') { $null } else { 'Service\' }
            $command = -join @($command, "`r`nSet-Item WSMAN:\localhost\$subdir$($setting.Key.Replace('WinRm','')) $($settingValue) -Force")
        }

        [System.IO.File]::WriteAllText("$vhdVolume\WinRmCustomization.ps1", $command)
    
        Write-ProgressIndicator
        
        $unattendXmlContent = Get-UnattendedContent
        $unattendXmlContent.Save("$VhdVolume\Unattend.xml")
        Write-PSFMessage "`tUnattended file copied to VM Disk '$vhdVolume\unattend.xml'"
        
        [void](Dismount-DiskImage -ImagePath $path)
        Write-PSFMessage "`tdisk image dismounted"
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

    Hyper-V\Set-VM -Name $Machine.ResourceName @param

    Hyper-V\Set-VM -Name $Machine.ResourceName -ProcessorCount $Machine.Processors

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
        Hyper-V\Checkpoint-VM -VM (Hyper-V\Get-VM -Name $Machine.ResourceName) -SnapshotName 'Post OS Installation'
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

    $writeVmConnectConfigFile = Get-LabConfigurationItem -Name VMConnectWriteConfigFile
    if ($writeVmConnectConfigFile)
    {
        New-LWHypervVmConnectSettingsFile -VmName $Machine.Name
    }

    Write-LogFunctionExit

    return $true
}
