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
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )
    
    Write-LogFunctionEntry

    $script:lab = Get-Lab
    
    if (Get-VM -Name $Machine.Name -ErrorAction SilentlyContinue)
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "The machine '$Machine' does already exist" -Type Warning
        return $false
    }

    Write-Verbose "Creating machine with the name '$($Machine.Name)' in the path '$VmPath'"

    #region Unattend XML settings
    if (-not $Machine.ProductKey)
    {
        $Machine.ProductKey = $Machine.OperatingSystem.ProductKey
    }
            
    Import-UnattendedContent -Content $Machine.UnattendedXmlContent
    Set-UnattendedComputerName -ComputerName $Machine.Name
    
    #region network adapter settings
    $macAddressPrefix = '0017FA'
    $macAddressesInUse = @(Get-VM | Get-VMNetworkAdapter | Select-Object -ExpandProperty MacAddress)
    $macAddressesInUse += (Get-LabMachine).NetworkAdapters.MacAddress

    $macIdx = 0
    while ("$macAddressPrefix{0:X6}" -f $macIdx -in $macAddressesInUse) { $macIdx++ }

    $adapters = New-Object System.Collections.ArrayList
    $adapters.AddRange(@($Machine.NetworkAdapters | Where-Object { $_.Ipv4Address } | Sort-Object -Property { $_.Ipv4Address[0] }))
    $adapters.AddRange(@($Machine.NetworkAdapters | Where-Object { -not $_.Ipv4Address }))

    if ($Machine.IsDomainJoined)
    {
        #move the adapter that connects the machine to the domain to the top
        $dc = Get-LabMachine -Role RootDC, FirstChildDC | Where-Object { $_.DomainName -eq $Machine.DomainName }
        
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
            $rootDomainName = Get-LabMachine -Role RootDC | Select-Object -First 1 | Select-Object -ExpandProperty DomainName
            $ipSettings.Add('DnsDomain', $rootDomainName)
        }
                
        if ($adapter.ConnectionSpecificDNSSuffix) { $ipSettings.Add('DnsDomain', $adapter.ConnectionSpecificDNSSuffix) }
        $ipSettings.Add('UseDomainNameDevolution', (([string]($adapter.AppendParentSuffixes)) = 'true'))
        if ($adapter.AppendDNSSuffixes)           { $ipSettings.Add('DNSSuffixSearchOrder', $adapter.AppendDNSSuffixes -join ',') }
        $ipSettings.Add('EnableAdapterDomainNameRegistration', ([string]($adapter.DnsSuffixInDnsRegistration)).ToLower())

        $ipSettings.Add('DisableDynamicUpdate', ([string](-not $adapter.RegisterInDNS)).ToLower())
                
                

        switch ($Adapter.NetbiosOptions)
        {                
            'Default'  { $ipSettings.Add('NetBIOSOptions', '0') }
            'Enabled'  { $ipSettings.Add('NetBIOSOptions', '1') }
            'Disabled' { $ipSettings.Add('NetBIOSOptions', '2') }
        }
                
                
        Add-UnattendedNetworkAdapter @ipSettings
    }
            
    Add-UnattendedRenameNetworkAdapters
    #endregion network adapter settings
            
    Set-UnattendedAdministratorPassword -Password $Machine.InstallationUser.Password
    Set-UnattendedAdministratorName -Name $Machine.InstallationUser.UserName
            
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

    $disableWindowsDefender = (Get-Module -Name AutomatedLab)[0].PrivateData.DisableWindowsDefender
    if (-not $disableWindowsDefender)
    {
        Set-UnattendedWindowsDefender -Enabled $false
    }

    $setLocalIntranetSites = (Get-Module -Name AutomatedLab)[0].PrivateData.SetLocalIntranetSites
    if ($setLocalIntranetSites -ne 'None' -or $setLocalIntranetSites -ne $null)
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

    Set-WindowsFirewallState -State $Machine.EnableWindowsFirewall

    if ($Machine.Roles.Name -contains 'RootDC' -or 
        $Machine.Roles.Name -contains 'FirstChildDC' -or 
        $Machine.Roles.Name -contains 'DC' -or 
    $Machine.OperatingSystem.Installation -eq 'Nano Server')
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
            Set-UnattendedDomain -DomainName $Machine.DomainName -Username $domain.Administrator.UserName -Password $domain.Administrator.Password
        }
    }

    #set the Generation for the VM depending on SupportGen2VMs, host OS version and VM OS version
    $hostOsVersion = [System.Version](Get-CimInstance -ClassName Win32_OperatingSystem).Version

    $generation = if ($PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.SupportGen2VMs)
    {
        if ($hostOsVersion -ge [System.Version]6.3 -and $Machine.OperatingSystem.Version -ge [System.Version]6.2)
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
    
    $vmPath = $lab.GetMachineTargetPath($Machine.Name)
    $path = "$vmPath\$($Machine.Name).vhdx"
    Write-Verbose "`tVM Disk path is '$path'"
    
    if (Test-Path -Path $path)
    {
        Write-ScreenInfo -Message "The disk $path does already exist. Disk cannot be created" -Type Warning
        return $false
    }
    
    Write-ProgressIndicator
    
    $referenceDiskPath = $Machine.OperatingSystem.BaseDiskPath
    $systemDisk = New-VHD -Path $path -Differencing -ParentPath $referenceDiskPath -ErrorAction Stop
    Write-Verbose "`tcreated differencing disk '$($systemDisk.Path)' pointing to '$ReferenceVhdxPath'"
    
    Write-ProgressIndicator

    $vm = New-VM -Name $Machine.Name `
    -MemoryStartupBytes ($Machine.Memory) `
    -VHDPath $systemDisk.Path `
    -Path $VmPath `
    -Generation $generation `
    -ErrorAction Stop
    
    Set-LWHypervVMDescription -ComputerName $Machine -Hashtable @{
        CreatedBy = '{0} ({1})' -f $PSCmdlet.MyInvocation.MyCommand.Module.Name, $PSCmdlet.MyInvocation.MyCommand.Module.Version
        CreationTime = Get-Date
        LabName = (Get-Lab).Name
        InitState = [AutomatedLab.LabVMInitState]::Uninitialized
    }

    $isUefi = try
    {
        Get-SecureBootUEFI -Name SetupMode
    }
    catch { }
    
    if ($isUefi -and $vm.Generation -ge 2)
    {
        $vm | Set-VMFirmware -EnableSecureBoot Off -SecureBootTemplate MicrosoftUEFICertificateAuthority
    }
    
    #remove the unconnected default network adapter
    $vm | Remove-VMNetworkAdapter
    foreach ($adapter in $adapters)
    {
        #external switches will be connected after the domain join and after the network order is configures correctly
        if ($adapter.VirtualSwitch.SwitchType -eq 'External' -and $adapters.Count -gt 1)
        {
            $vm | Add-VMNetworkAdapter -Name $adapter.VirtualSwitch -StaticMacAddress $adapter.MacAddress
        }
        else
        {
            $vm | Add-VMNetworkAdapter -Name $adapter.VirtualSwitch -SwitchName $adapter.VirtualSwitch -StaticMacAddress $adapter.MacAddress
        }
    }
    
    Write-Verbose "`tMachine '$Name' created"
    
    $automaticStartAction = 'Nothing'
    $automaticStartDelay  = 0
    $automaticStopAction  = 'ShutDown'
    
    if ($Machine.HypervProperties.AutomaticStartAction) { $automaticStartAction = $Machine.HypervProperties.AutomaticStartAction }
    if ($Machine.HypervProperties.AutomaticStartDelay)  { $automaticStartDelay  = $Machine.HypervProperties.AutomaticStartDelay  }
    if ($Machine.HypervProperties.AutomaticStopAction)  { $automaticStopAction  = $Machine.HypervProperties.AutomaticStopAction  }
    $vm | Set-VM -AutomaticStartAction $automaticStartAction -AutomaticStartDelay $automaticStartDelay -AutomaticStopAction $automaticStopAction
    
    Write-ProgressIndicator
    
    Mount-DiskImage -ImagePath $path
    $VhdDisk = Get-DiskImage -ImagePath $path | Get-Disk
    $VhdPartition = Get-Partition -DiskNumber $VhdDisk.Number
    
    if ($VhdPartition.Count -gt 1)
    {
        #for Generation 2 VMs
        $vhdOsPartition = $VhdPartition | Where-Object Type -eq 'Basic'
        $VhdVolume = "$($VhdOsPartition.DriveLetter):"
    }
    else
    {
        #for Generation 1 VMs
        $VhdVolume = "$($VhdPartition.DriveLetter):"
    }
    
    Write-Verbose "`tDisk mounted to drive $VhdVolume"

    #Get-PSDrive needs to be called to update the PowerShell drive list
    Get-PSDrive | Out-Null
    
    $unattendXmlContent = Get-UnattendedContent
    $unattendXmlContent.Save("$VhdVolume\Unattend.xml")
    Write-Verbose "`tUnattended file copied to VM Disk '$vhdVolume\unattend.xml'"
    
    if ($Machine.OperatingSystem.Installation -eq 'Nano Server')
    {
        $cmd = New-Object System.Text.StringBuilder
        $cmd.AppendLine('cd c:\')
        foreach ($adapter in $Machine.NetworkAdapters)
        {
            # Defining these as variables in case at some point need to allow them to be overridden.
            $interfaceAlias = 'Ethernet'
            $addressFamiyly = 'IPv4'
            
            If ($adapter.Ipv4Address.Count)
            {
                $mac = (Get-StringSection -String $adapter.MacAddress -SectionSize 2) -join '-'                
                $cmd.AppendLine(('for /f "tokens=*" %%a in (''powershell -noprofile -command "Get-NetAdapter | where-object MacAddress -eq {0} | Select-object -ExpandProperty Name -f 1"'') do (set adapterName=%%a)' -f $mac)) | Out-Null
                $cmd.AppendLine("ECHO Adapter Name is '%adapterName%'")
                
                if ($adapter.Ipv4Gateway.Count)
                {
                    $cmd.AppendLine(('netsh interface ip set address "%adapterName%" static addr={0} mask={1} gateway={2}' -f $adapter.Ipv4Address[0].IpAddress, $adapter.Ipv4Address[0].Netmask, $adapter.Ipv4Gateway[0].IpAddress)) | Out-Null
                }
                else
                {
                    $cmd.AppendLine(('netsh interface ip set address "%adapterName%" static addr={0} mask={1}' -f $adapter.Ipv4Address[0].IpAddress, $adapter.Ipv4Address[0].Netmask)) | Out-Null
                }
                
            }
            
            if ($adapter.Ipv4DnsServers.Count)
            {
                $index = 1
                foreach ($dnsSever in $adapter.Ipv4DnsServers)
                {
                    if ($dnsSever -eq '0.0.0.0') { continue }
                    
                    if ($index -eq 1)
                    {
                        $cmd.AppendLine(('netsh interface ip set dns "%adapterName%" static addr={0}' -f $dnsSever.IpAddress)) | Out-Null
                    }
                    else
                    {
                        $cmd.AppendLine(('netsh interface ip set dns "%adapterName%" static addr={0} index={1}' -f $dnsSever.IpAddress, $index)) | Out-Null
                    }
                    $index++
                }
            }
        }
        
        New-Item "$VhdVolume\Windows\Setup\Scripts" -ItemType Directory | Out-Null
        Set-Content -Path "$VhdVolume\Windows\Setup\Scripts\SetupComplete.cmd" -Value $cmd.ToString()
        Set-Content -Path "$VhdVolume\net.cmd" -Value $cmd.ToString()
    }
    
    #copy AL tools to lab machine and optionally the tools folder
    $drive = New-PSDrive -Name $VhdVolume[0] -PSProvider FileSystem -Root $VhdVolume

    Write-Verbose 'Copying AL tools to VHD...'
    $tempPath = "$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tempPath | Out-Null
    Copy-Item -Path "$((Get-Module -Name AutomatedLab)[0].ModuleBase)\Tools\HyperV\*" -Destination $tempPath -Recurse
    foreach ($file in (Get-ChildItem -Path $tempPath -Recurse -File))
    {
        $file.Decrypt()
    }
    Copy-Item -Path "$tempPath\*" -Destination "$vhdVolume\Windows" -Recurse

    Remove-Item -Path $tempPath -Recurse
    
    Write-Verbose '...done'

    if ($Machine.ToolsPath.Value)
    {
        $toolsDestination = "$vhdVolume\Tools"
        if ($Machine.ToolsPathDestination)
        {
            $toolsDestination = "$($toolsDestination[0])$($Machine.ToolsPathDestination.Substring(1,$Machine.ToolsPathDestination.Length - 1))"
        }
        Write-Verbose 'Copying tools to VHD...'
        Copy-Item -Path $Machine.ToolsPath -Destination $toolsDestination -Recurse
        Write-Verbose '...done'
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
    
    Dismount-DiskImage -ImagePath $path
    Write-Verbose "`tdisk image dismounted"
    
    Write-ProgressIndicator
    
    Write-Verbose "`tSettings RAM, start and stop actions"
    $param = @{}
    $param.Add('MemoryStartupBytes', $Machine.Memory)
    if ($Machine.MaxMemory) { $param.Add('MemoryMaximumBytes', $Machine.MaxMemory) }
    if ($Machine.MinMemory) { $param.Add('MemoryMinimumBytes', $Machine.MinMemory) }
    
    if ($Machine.MaxMemory -or $Machine.MinMemory)
    { 
        $param.Add('DynamicMemory', $true)
        Write-Verbose "`tSettings dynamic memory to MemoryStartupBytes $($Machine.Memory), minimum $($Machine.MinMemory), maximum $($Machine.MaxMemory)"
    }
    else
    {
        Write-Verbose "`tSettings static memory to $($Machine.Memory)"
        $param.Add('StaticMemory', $true)
    }

    Set-VM -Name $Machine.Name @param
    
    Set-VM -Name $Machine.Name -ProcessorCount $Machine.Processors
    
    if ($DisableIntegrationServices)
    {
        Disable-VMIntegrationService -VMName $Machine.Name -Name 'Time Synchronization'
    }

    if ($Generation -eq 1)
    {
        Set-VMBios -VMName $Machine.Name -EnableNumLock
    }
    
    Write-Verbose "Creating snapshot named '$($Machine.Name) - post OS Installation'"
    if ($CreateCheckPoints)
    {
        Checkpoint-VM -VM (Get-VM -Name $Machine.Name) -SnapshotName 'Post OS Installation'
    }

    if ($Machine.Disks.Name)
    {
        $disks = Get-LabVHDX -Name $Machine.Disks.Name
        foreach ($disk in $disks)
        {
            Add-LWVMVHDX -VMName $Machine.Name -VhdxPath $disk.Path
        }
    }
            
    Write-LogFunctionExit
    
    return $true
}
#endregion New-LWHypervVM

#region Remove-LWHypervVM
function Remove-LWHypervVM
{
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
            Write-Verbose "Deleting saved state of VM '$($Name)'"
            Remove-VMSavedState -VMName $Name
        }
        else
        {
            Write-Verbose "Stopping VM '$($Name)'"
            Stop-VM -TurnOff -Name $Name -Force
        }
    
        Write-Verbose "Removing VM '$($Name)'"
        Remove-VM -Name $Name -Force

        Write-Verbose "Removing VM files for '$($Name)'"
        Remove-Item -Path $vmPath -Force -Confirm:$false -Recurse
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LWHypervVM

#region Wait-LWHypervVM
workflow Wait-LWHypervVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [int]$Port = 5985,
        
        [switch]$TestCredSsp
    )
    
    Write-LogFunctionEntry
    
    foreach -parallel -throttlelimit 50 ($machine in $ComputerName)
    {
        sequence
        {
            Write-Verbose -Message "Waiting for machine '$machine' to come online..."
            $uptimeCheck = 1
            $uptimeCheckTotal = 5
            
            $uptime = (Get-VM -Name $machine).Uptime.TotalSeconds
            if ($uptime -gt 180)
            {
                Write-Verbose -Message "Machine '$machine' has been been running for more than 3 minutes. Only one online check is done."
                $uptimeCheckTotal = 1
            }
            
            $ping = New-Object -TypeName System.Net.Networkinformation.Ping
            
            $pingAnswer = ''
            $pingCount = 0
            Do
            {
                try
                {
                    $pingAnswer = $ping.Send($machine, 1000)
                    $pingCount++
                    
                    #for each 10th test print out a message
                    if ($pingCount % 10 -eq 0)
                    {
                        Write-Verbose -Message "'$machine' was not reachable by ICMP"
                    }
                }
                catch
                {
                    
                }
                Start-Sleep -Milliseconds 500
                Write-ProgressIndicator
            }
            Until ($pingAnswer.Status -eq 'Success')
            Write-Verbose -Message "'$machine' was reachable by ICMP, testing WinRM"
            
            $i = 0
            while ($uptimeCheck -le $uptimeCheckTotal)
            {
                $result = Test-WSMan -ComputerName $machine -ErrorAction SilentlyContinue
                if ($result)
                {
                    Write-Verbose -Message "'$machine' was reachable by WinRM, check $uptimeCheck of $uptimeCheckTotal"
                    $uptimeCheck++
                }
                else
                {
                    if ($i % 10 -eq 0)
                    {
                        Write-Verbose -Message "'$machine' was not reachable by WinRM"
                    }
                }
                Start-Sleep -Seconds 3
                $i++
                Write-ProgressIndicator
            }
            
            if ($result)
            {
                Write-Verbose -Message "'$machine' is online and reachable by WinRM"
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine
                InlineScript { $machineMetadata.InitState = 1 } #ReachedByAutomatedLab
                
                Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $machine
            }
        }
    }
    
    Write-LogFunctionExit
}
#endregion Wait-LWHypervVM

#region Wait-LWHypervVMRestart
function Wait-LWHypervVMRestart
{
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
    
    $machines = Get-LabMachine -ComputerName $ComputerName

    $machines | Add-Member -Name Uptime -MemberType NoteProperty -Value 0 -Force
    foreach ($machine in $machines)
    {
        $machine.Uptime = (Get-VM -Name $machine).Uptime.TotalSeconds
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
        if (((Get-Date) - $progressIndicatorStart).TotalSeconds -gt 45)
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
                    if (($diskTime[(($diskTime).Count-15)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 50 -and ($diskTime[(($diskTime).Count-5)..(($diskTime).Count)] | Measure-Object -Average).Average -lt 60)
                    {
                        Write-Verbose -Message 'Starting next machine'
                        $lastMachineStart = (Get-Date)
                        Start-LabVM -ComputerName $StartMachinesWhileWaiting[0]
                        $StartMachinesWhileWaiting = $StartMachinesWhileWaiting | Where-Object { $_ -ne $StartMachinesWhileWaiting[0] }
                        if ($StartMachinesWhileWaiting)
                        {
                            Start-LabVM -ComputerName $StartMachinesWhileWaiting[0]
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
            $currentMachineUptime = (Get-VM -Name $machine).Uptime.TotalSeconds
            Write-Debug -Message "Uptime machine '$($machine.name)'=$currentMachineUptime, Saved uptime=$($machine.uptime)"
            if ($machine.Uptime -ne 0 -and $currentMachineUptime -lt $machine.Uptime)
            {
                Write-Verbose -Message "Machine '$machine' has now restarted"
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
                        Write-Verbose "There was a non-critical error in job $($job.ID) '$($job.Name)' with the message: '($nonCriticalError.Exception.Message)'"
                    }
                }
            }
        }
    }
    until (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0 -or (Get-Date).AddMinutes(-$TimeoutInMinutes) -gt $start)    

    if (($machines.Uptime | Measure-Object -Maximum).Maximum -eq 0)
    {
        Write-Verbose -Message "All machines have now restarted ($($machines.name -join ', ')"
    }
    
    if ((Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
    {
        foreach ($Computer in $ComputerName)
        {
            if ($machineInfo.($Computer) -gt 0)
            {
                Write-Error -Message "Timeout while waiting for computer '$computer' to restart." -TargetObject $computer
            }
        }
    }
    
    if ($delayedStart)
    {
        Start-LabVM -ComputerName $delayedStart
    }
    
    if ((-not $NoNewLine) -and $ProgressIndicator)
    {
        Write-ProgressIndicatorEnd
    }
    
    Write-LogFunctionExit
}
#endregion Wait-LWHypervVMRestart

#region Start-LWHypervVM
function Start-LWHypervVM
{
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
    
    foreach ($Name in $ComputerName)
    {
        $machine = Get-LabMachine -ComputerName $Name
        $machineMetadata = Get-LWHypervVMDescription -ComputerName $Name
            
        try
        {
            Start-VM -Name $Name -ErrorAction Stop

            if ($machine.NetworkAdapters.Count -gt 1 -and 
            ($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected) -ne [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected)
            {            
                Repair-LWHypervNetworkConfig -ComputerName $Name
                $machineMetadata.InitState = [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected
                Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $Name
            }            
        }
        catch
        {
            $ex = New-Object System.Exception("Could not start Hyper-V machine '$ComputerName': $($_.Exception.Message)", $_.Exception)
            throw $ex
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
    
    $nanoServersToJoin = Get-LabMachine -ComputerName $ComputerName |
    Where-Object { $_.IsDomainJoined -and -not $_.HasDomainJoined -and $_.OperatingSystem.Installation -eq 'Nano Server' }
    
    if ($nanoServersToJoin)
    {
        Wait-LabVM -ComputerName $nanoServersToJoin
            
        Join-LabVMDomain -Machine $nanoServersToJoin
        Restart-LabVM -ComputerName $nanoServersToJoin -Wait
    }
    
    Write-LogFunctionExit
}
#endregion Start-LWHypervVM

#region Stop-LWHypervVM
function Stop-LWHypervVM
{
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
        $jobs = Invoke-LabCommand -ComputerName $ComputerName -NoDisplay -AsJob -PassThru -ScriptBlock { shutdown.exe -s -t 0 -f; $LastExitCode }
        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine
        $failedJobs = $jobs | Where-Object {$_.State -eq 'Failed'}
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Hyper-V VM(s): '$($failedJobs.Location)'" -Type Error
        }
    }
    else
    {
        $jobs = @()
        foreach ($name in $ComputerName)
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
workflow Save-LWHypervVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )
    
    sequence
    {
        Write-LogFunctionEntry
        
        foreach -parallel -throttlelimit 50 ($Name in $ComputerName)
        {
            Save-VM -Name $Name
        }
        
        Write-LogFunctionExit
    }
}
#endregion Save-LWHypervVM

#region Checkpoint-LWHypervVM
workflow Checkpoint-LWHypervVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory)]
        [string]$SnapshotName
    )
    
    Write-LogFunctionEntry
    
    sequence
    {
        Write-LogFunctionEntry
        
        #only if we create a checkpoint of more than two machines we save them first and start them after taking the checkpoints
        #this is required for replicating applications to make sure the snapshots are taken very closely
        
        $WORKFLOW:runningMachines = @()
        
        Write-Verbose -Message 'Remembering all running machines'
        if ($ComputerName.Count -gt 1)
        {
            foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
            {
                if ((Get-VM -Name $n -ErrorAction SilentlyContinue).State -eq 'Running')
                {
                    Suspend-VM -Name $n -ErrorAction SilentlyContinue
                    Save-VM -Name $n -ErrorAction SilentlyContinue
                    
                    Write-Verbose -Message "    '$n' was running"
                    $WORKFLOW:runningMachines += $n
                }
            }
            
            Start-Sleep -Seconds 5
        }
        
        foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
        {
            Checkpoint-VM -Name $n -SnapshotName $SnapshotName
        }
        
        Write-Verbose -Message "Checkpoint finished, starting the machines that were running previously ($($WORKFLOW:runningMachines.Count))"
        if ($ComputerName.Count -gt 1)
        {
            Start-Sleep -Seconds 5
            
            foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
            {
                if ($n -in $WORKFLOW:runningMachines)
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
        
        Write-LogFunctionExit
    }
}
#endregion Checkpoint-LWVM

#region Remove-LWHypervVMSnapshot
workflow Remove-LWHypervVMSnapshot
{
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
    
    foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
    {
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
            Write-Warning -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
        }
        else
        {
            Remove-VMSnapshot -VMName $n -Name $snapshot.Name -IncludeAllChildSnapshots -ErrorAction SilentlyContinue
        }
    }
    
    Write-LogFunctionExit
}
#endregion Remove-LWHypervVMSnapshot

#region Restore-LWHypervVMSnapshot
workflow Restore-LWHypervVMSnapshot
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory)]
        [string]$SnapshotName
    )
    
    sequence
    {
        Write-LogFunctionEntry
        
        $WORKFLOW:runningMachines = @()
        
        Write-Verbose -Message 'Remembering all running machines'
        foreach ($n in $ComputerName)
        {
            if ((Get-VM -Name $n -ErrorAction SilentlyContinue).State -eq 'Running')
            {
                Write-Verbose -Message "    '$n' was running"
                $WORKFLOW:runningMachines += $n
            }
        }
        
        if ($ComputerName.Count -gt 1)
        {
            foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
            {
                Suspend-VM -Name $n -ErrorAction SilentlyContinue
                Save-VM -Name $n -ErrorAction SilentlyContinue
            }
        }
        
        Start-Sleep -Seconds 5
        
        
        foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
        {
            $snapshot = Get-VMSnapshot -VMName $n | Where-Object -FilterScript {
                $_.Name -eq $SnapshotName
            }
            
            if (-not $snapshot)
            {
                Write-Warning -Message "The machine '$n' does not have a snapshot named '$SnapshotName'"
            }
            else
            {
                Restore-VMSnapshot -VMName $n -Name $SnapshotName -Confirm:$false
                Set-VM -Name $n -Notes (Get-VMSnapshot -VMName $n -Name $SnapshotName).Notes
            }
        }
        
        Write-Verbose -Message "Restore finished, starting the machines that were running previously ($($WORKFLOW:runningMachines.Count))"
        if ($ComputerName.Count -gt 1)
        {
            Start-Sleep -Seconds 5
            
            foreach -parallel -ThrottleLimit 20 ($n in $ComputerName)
            {
                if ($n -in $WORKFLOW:runningMachines)
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
        
        Write-LogFunctionExit
    }
}
#endregion Restore-LWHypervVMSnapshot

#region Get-LWHypervVMStatus
function Get-LWHypervVMStatus
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )
    
    Write-LogFunctionEntry
    
    $result = @{ }
    $vms = Get-VM | Where-Object Name -in $ComputerName
    
    foreach ($vm in $vms)
    {
        if ($vm.State -eq 'Running')
        {
            $result.Add($vm.Name, 'Started')
        }
        elseif ($vm.State -eq 'Off')
        {
            $result.Add($vm.Name, 'Stopped')
        }
        else
        {
            $result.Add($vm.Name, 'Unknown')
        }
    }
    
    $result
    
    Write-LogFunctionExit
}
#endregion Get-LWHypervVMStatus

#region Enable-LWHypervVMRemoting
function Enable-LWHypervVMRemoting
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabMachine -ComputerName $ComputerName
    
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

    $machines = Get-LabMachine -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        Write-Verbose -Message "Adding DVD drive '$IsoPath' to machine '$machine'"
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
                    $drive = Add-VMDvdDrive -VMName $machine -Path $IsoPath -ErrorAction Stop -Passthru
                }
                else
                {
                    if (-not (Get-VMDvdDrive -VMName $machine))
                    {
                        throw "No DVD drive exist for machine '$machine'. Machine is generation 1 and DVD drive needs to be crate in advance (during creation of the machine). Cannot continue."
                    }
                    $drive = Set-VMDvdDrive -VMName $machine -Path $IsoPath -ErrorAction Stop -Passthru
                }
                
                Start-Sleep -Seconds $delayBeforeCheck[$delayIndex]
                    
                if ((Get-VMDvdDrive -VMName $machine).Path -contains $IsoPath)
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
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabMachine -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        if ($machine.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            Write-Verbose -Message "Removing DVD drive for machine '$machine'"
            Get-VMDvdDrive -VMName $machine | Remove-VMDvdDrive
        }
        else
        {
            Write-Verbose -Message "Setting DVD drive for machine '$machine' to null"
            Get-VMDvdDrive -VMName $machine | Set-VMDvdDrive -Path $null
        }
    }
}
#endregion Dismount-LWIsoImage

#region Repair-LWHypervNetworkConfig
function Repair-LWHypervNetworkConfig
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $machine = Get-LabMachine -ComputerName $ComputerName

    Wait-LabVM -ComputerName $machine

    #remoting does serialization with a depth of 1. Here we need more
    $machineStream = [System.Management.Automation.PSSerializer]::Serialize($machine, 4)

    Invoke-LabCommand -ComputerName $machine -ActivityName "Network config on '$machine' (renaming and ordering)" -ScriptBlock {
        $machine = [System.Management.Automation.PSSerializer]::Deserialize($machineStream)

        Write-Verbose "Renaming network adapters"
        #rename the adapters as defined in the lab
        
        $newNames = @()
        foreach ($adapterInfo in $machine.NetworkAdapters)
        {
            $newName = Add-StringIncrement -String $adapterInfo.VirtualSwitch.Name
            while ($newName -in $newNames)
            {
                $newName = Add-StringIncrement -String $newName
            }
            $newNames += $newName
            $adapterInfo.VirtualSwitch.Name = $newName
                
            if ($machine.OperatingSystem.Version.Major -lt 6 -and $machine.OperatingSystem.Version.Minor -lt 2)
            {
                $mac = (Get-StringSection -String $adapterInfo.MacAddress -SectionSize 2) -join ':'
                $filter = 'MACAddress = "{0}"' -f $mac
                Write-Verbose "Looking for network adapter with using filter '$filter'"
                $adapter = Get-WmiObject -Class Win32_NetworkAdapter -Filter $filter
    
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
                Write-Verbose "Setting the order for adapter '$($adapterInfo.VirtualSwitch.Name)'"
                do {
                    nvspbind.exe /+ $adapterInfo.VirtualSwitch.Name ms_tcpip | Out-File -FilePath c:\nvspbind.log -Append
                    $i++

                    if ($i -gt $retries) { return }
                }  until ($LASTEXITCODE -eq 14)
            }
        }
    
    } -Function (Get-Command -Name Get-StringSection, Add-StringIncrement) -Variable (Get-Variable -Name machineStream) -NoDisplay

    foreach ($adapterInfo in $machine.NetworkAdapters)
    {
        $vmAdapter = Get-VMNetworkAdapter -VMName $machine -Name $adapterInfo.VirtualSwitch.Name
        
        if ($adapterInfo.VirtualSwitch.Name -ne $vmAdapter.SwitchName)
        {
            $vmAdapter | Connect-VMNetworkAdapter -SwitchName $adapterInfo.VirtualSwitch.Name
        }
    }
    
    Write-LogFunctionExit
}
#endregion Repair-LWHypervNetworkConfig

#region Get / Set-LWHypervVMDescription
function Set-LWHypervVMDescription
{
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
    
    $importMethodInfo = $type.GetMethod('ImportFromString', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
    $dictionary = $importMethodInfo.Invoke($null, $vm.Notes)
        
    $dictionary
        
    Write-LogFunctionExit
}
#endregion Get / Set-LWHypervVMDescription