$PSDefaultParameterValues = @{
    '*-Azure*:Verbose' = $false
    '*-Azure*:Warning' = $false
    'Import-Module:Verbose' = $false
}

#region New-LWAzureVM
function New-LWAzureVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )
	
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    
    $cloudServiceName = $lab.Name
    if ($machine.AzureProperties)
    {
        if ($machine.AzureProperties.ContainsKey('CloudServiceName'))
        {
            #if the cloud service name is provided for the machine, it replaces the default
            $cloudServiceName = $machine.AzureProperties.CloudServiceName
        }
    }
    
    $machineServiceName = $Machine.AzureProperties.CloudServiceName
    if (-not $machineServiceName)
    {
        $machineServiceName = (Get-LabAzureDefaultService).ServiceName
    }
    Write-Verbose -Message "Target service for machine: '$machineServiceName'"
    
    if (-not $global:cacheVMs)
    {
        $global:cacheVMs = Get-AzureVM -WarningAction SilentlyContinue
    }

    if ($global:cacheVMs | Where-Object {$_.Name -eq $Machine.Name -and $_.ServiceName -eq $cloudServiceName})
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "Machine '$($machine.name)' already exist. Skipping creation of this machine" -Type Warning
        Return $false
    }

    Write-Verbose -Message "Creating container 'automatedlabdisks' for additional disks"
    $container = Get-AzureStorageContainer -Name automatedlabdisks -ErrorAction SilentlyContinue
    if (-not $container)
    {
        $container = New-AzureStorageContainer -Name automatedlabdisks
    }

    Write-Verbose -Message "Scheduling creation Azure machine '$Machine'"

    #random number in the path to prevent conflicts
    $rnd = (Get-Random -Minimum 1 -Maximum 1000).ToString('0000')
    $osVhdLocation = "http://$((Get-LabAzureDefaultStorageAccount).StorageAccountName).blob.core.windows.net/automatedlab1/$($machine.Name)OsDisk$rnd.vhd"
    $lab.AzureSettings.VmDisks.Add($osVhdLocation)
    Write-Verbose -Message "The location of the VM disk is '$osVhdLocation'"

    $adminUserName = $Machine.InstallationUser.UserName
    $adminPassword = $Machine.InstallationUser.Password
			
    $subnet = (Get-LabXmlAzureNetworkVirtualNetworkSite -Name $Machine.Network[0]).Subnets.Subnet.name | Where-Object { $_ -ne 'GatewaySubnet' }
    Write-Verbose -Message "Subnet for the VM is '$subnet'"
    
    #if this machine has a SQL Server role
    if ($Machine.Roles.Name -match 'SQLServer(?<SqlVersion>\d{4})')
    {    
        #get the SQL Server version defined in the role
        $sqlServerRoleName = $Matches[0]
        $sqlServerVersion = $Matches.SqlVersion
    }

    #if this machine has a Visual Studio role
    if ($Machine.Roles.Name -match 'VisualStudio(?<Version>\d{4})')
    {
        $visualStudioRoleName = $Matches[0]        
        $visualStudioVersion = $Matches.Version
    }

    #if this machine has a SharePoint role
    if ($Machine.Roles.Name -match 'SharePoint(?<Version>\d{4})')
    {
        $sharePointRoleName = $Matches[0]
        $sharePointVersion = $Matches.Version
    }
            
    if ($sqlServerRoleName)
    {
        Write-Verbose -Message 'This is going to be a SQL Server VM'
        $pattern = 'SQL Server (?<SqlVersion>\d{4}) (?<SqlIsR2>R2)? ?(?<SqlServicePack>RTM|SP\d) Standard on (?<OS>Windows Server \d{4} (R2)?)'
                
        #get all SQL images machting the RegEx pattern and then get only the latest one
        $sqlServerImages = $lab.AzureSettings.VmImages |
        Where-Object ImageFamily -Match $pattern | 
        Group-Object -Property Imagefamily | 
        ForEach-Object { 
            $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1
        }

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($sqlServerImage in $sqlServerImages)
        {
            $sqlServerImage.ImageFamily -match $pattern | Out-Null

            $sqlServerImage | Add-Member -Name SqlVersion -Value $Matches.SqlVersion -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlIsR2 -Value $Matches.SqlIsR2 -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlServicePack -Value $Matches.SqlServicePack -MemberType NoteProperty -Force
    
            $sqlServerImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImageName = $sqlServerImages | Where-Object { $_.SqlVersion -eq $sqlServerVersion -and $_.OS.Version -eq $machineOs.Version } |
        Sort-Object -Property SqlServicePack -Descending |
        Select-Object -ExpandProperty ImageName -First 1

        if (-not $vmImageName)
        {
            Write-Warning 'SQL Server image could not be found. The following combinations are currently supported by Azure:'
            foreach ($sqlServerImage in $sqlServerImages)
            {
                Write-Host $sqlServerImage.Label
            }

            throw "There is no Azure VM image for '$sqlServerRoleName' on operating system '$($machine.OS)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($visualStudioRoleName)
    {
        Write-Verbose -Message 'This is going to be a Visual Studio VM'

        $pattern = 'Visual Studio (?<Edition>\w+) (?<Version>\d{4}) ((Update) (?<Update>\d))?.+ on (?<OS>Windows Server \d{4} (R2)?)$'
                
        #get all SQL images machting the RegEx pattern and then get only the latest one
        $visualStudioImages = $lab.AzureSettings.VmImages |
        Where-Object ImageFamily -Match $pattern | 
        Group-Object -Property Imagefamily | 
        ForEach-Object { 
            $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1
        }

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($visualStudioImage in $visualStudioImages)
        {
            $visualStudioImage.ImageFamily -match $pattern | Out-Null

            $visualStudioImage | Add-Member -Name Version -Value $Matches.Version -MemberType NoteProperty -Force
            $visualStudioImage | Add-Member -Name Update -Value $Matches.Update -MemberType NoteProperty -Force
    
            $visualStudioImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImageName = $visualStudioImages | Where-Object { $_.Version -eq $visualStudioVersion -and $_.OS.Version -eq $machineOs.Version } |
        Sort-Object -Property Update -Descending |
        Select-Object -ExpandProperty ImageName -First 1

        if (-not $vmImageName)
        {
            Write-Warning 'Visual Studio image could not be found. The following combinations are currently supported by Azure:'
            foreach ($visualStudioImage in $visualStudioImages)
            {
                Write-Host $visualStudioImage.Label
            }

            throw "There is no Azure VM image for '$visualStudioRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($sharePointRoleName)
    {
        Write-Verbose -Message 'This is going to be a SharePoint VM'

        $sharePoint2013Pattern = '\w+__SharePoint-(?<Version>2013)'
        $windowsPattern = 'Windows Server (?<SKU>\w+) (?<Version>\d{4}) (\w+)'
                
        #get all SQL images machting the RegEx pattern and then get only the latest one
        $sharePointImages = $lab.AzureSettings.VmImages |
        Where-Object ImageName -Match $sharePoint2013Pattern |
        Sort-Object -Property PublishedDate -Descending | Select-Object -First 1

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($sharePointImage in $sharePointImages)
        {
            $sharePointImage.ImageName -match $sharePoint2013Pattern | Out-Null
            $sharePointImage | Add-Member -Name Version -Value $Matches.Version -MemberType NoteProperty -Force

            $sharePointImage.ImageFamily -match $windowsPattern | Out-Null
            $sharePointImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.Version)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        Write-Warning "The SharePoint 2013 Trial image in Azure does not have any information about the OS anymore, hence this operating system specified is ignored. There is only $($sharePointImages.Count) image available."
        
        #$vmImageName = $sharePointImages | Where-Object { $_.Version -eq $sharePointVersion -and $_.OS.Version -eq $machineOs.Version } |
        $vmImageName = $sharePointImages | Where-Object Version -eq $sharePointVersion |
        Sort-Object -Property Update -Descending |
        Select-Object -ExpandProperty ImageName -First 1

        if (-not $vmImageName)
        {
            Write-Warning 'SharePoint image could not be found. The following combinations are currently supported by Azure:'
            foreach ($sharePointImage in $sharePointImages)
            {
                Write-Host $sharePointImage.Label $sharePointImage.ImageFamily
            }

            throw "There is no Azure VM image for '$sharePointRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    else
    {
        $vmImageName = (New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)).AzureImageName
        if (-not $vmImageName)
        {
            throw "There is no Azure VM image for the operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup."
        }

        $vmImageName = $lab.AzureSettings.VmImages |
        Where-Object ImageFamily -eq $vmImageName |
        Select-Object -ExpandProperty ImageName
    }
    Write-Verbose -Message "The following image '$vmImageName' was chosen"
    
    Write-ProgressIndicator
    
    if ($machine.AzureProperties.RoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.RoleSizeLabel -eq $machine.AzureProperties.RoleSize }
        Write-Verbose -Message "Using specified role size of The VM has the role size '$($roleSize.InstanceSize)'"
    }
    elseif ($machine.AzureProperties.UseAllRoleSizes)
    {
        $DefaultAzureRoleSize = $MyInvocation.MyCommand.Module.PrivateData.DefaultAzureRoleSize
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.MemoryInMB -ge $machine.Memory -and $_.Cores -ge $machine.Processors } |
        Sort-Object -Property MemoryInMB, Cores |
        Select-Object -First 1

        Write-Verbose -Message "Using specified role size of '$($roleSize.InstanceSize)'. VM was configured to all role sizes but constrained to role size '$DefaultAzureRoleSize' by psd1 file"
    }
    else
    {
        switch ($lab.AzureSettings.DefaultRoleSize)
        {
            'A' { $pattern = '^(ExtraLarge|ExtraSmall|Large|Medium|Small|A\d{1,2}|Basic_A\d{1,2})' }
            'D' { $pattern = '^Standard_D\d{1,2}' }
            'DS' { $pattern = '^Standard_DS\d{1,2}' }
            'G' { $pattern = '^Standard_G\d{1,2}' }
            default { $pattern = '^(ExtraLarge|ExtraSmall|Large|Medium|Small|A\d{1,2}|Basic_A\d{1,2})'}
        }
        
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object InstanceSize -Match $pattern |
        Where-Object { $_.MemoryInMB -ge ($machine.Memory / 1MB) -and $_.Cores -ge $machine.Processors } |
        Sort-Object -Property MemoryInMB, Cores |
        Select-Object -First 1

        Write-Verbose -Message "Using specified role size of '$($roleSize.InstanceSize)' out of role sizes '$pattern'"
    }
    
    if (-not $roleSize)
    {
        throw "Could not find an appropriate role size in Azure $($machine.Processors) cores and $($machine.Memory) MB of memory"
    }
    
    Write-ProgressIndicator
    
    if (Get-Job -Name "CreateAzureVM ($machineServiceName)*" -ErrorAction SilentlyContinue | Where-Object State -ne 'Completed')
    {
        Wait-LWLabJob -Name "CreateAzureVM ($machineServiceName)*" -NoDisplay -ProgressIndicator 10 -Timeout 30 -NoNewLine
    }

    $labVirtualNetworkDefinition = Get-LabVirtualNetworkDefinition

    Start-Job -Name "CreateAzureVM ($machineServiceName) ($Machine)" -ArgumentList $Machine,
    $Machine.NetworkAdapters[0].VirtualSwitch.Name,
    $subnet,
    $roleSize.InstanceSize,
    $vmImageName,
    $osVhdLocation,
    $adminUserName,
    $adminPassword,
    $machineServiceName,
    $labVirtualNetworkDefinition,
    $Machine.NetworkAdapters[0].Ipv4Address.IpAddress `
    -ScriptBlock {
        param
        (
            [object]$Machine, #AutomatedLab.Machine
            [string]$Vnet,
            [string]$Subnet,
            [string]$RoleSize,
            [string]$VmImageName,
            [string]$OsVhdLocation,
            [string]$AdminUserName,
            [string]$AdminPassword,
            [string]$MachineServiceName,
            [object[]]$LabVirtualNetworkDefinition, #AutomatedLab.VirtualNetwork[]
            [object]$DefaultIpAddress #AutomatedLab.IPAddress
        )

        Import-Module AutomatedLab
        
        $bvp = $VerbosePreference
        $VerbosePreference = 'Continue'
        
        Write-Verbose '-------------------------------------------------------'
        Write-Verbose "Machine: $($Machine.name)"
        Write-Verbose "Vnet: $Vnet"
        Write-Verbose "Subnet: $Subnet"
        Write-Verbose "RoleSize: $RoleSize"
        Write-Verbose "VmImageName: $VmImageName"
        Write-Verbose "OsVhdLocation: $OsVhdLocation"
        Write-Verbose "AdminUserName: $AdminUserName"
        Write-Verbose "AdminPassword: $AdminPassword"
        Write-Verbose "MachineServiceName: $MachineServiceName"
        Write-Verbose "DefaultIpAddress: $DefaultIpAddress"
        Write-Verbose '-------------------------------------------------------'
        
        $VerbosePreference = $bvp
        Import-Module -Name Azure
        $VerbosePreference = 'Continue'
        
        #$cert = New-AzureCertificateSetting -StoreName Root -Thumbprint (Get-LabAzureCertificate).ThumbPrint
        Write-Verbose -Message "Calling 'New-AzureVMConfig'"
        $vmConfig = New-AzureVMConfig -Name $Machine.Name -InstanceSize $RoleSize -ImageName $vmImageName -MediaLocation $OsVhdLocation
        
        Write-Verbose -Message "Calling 'Add-AzureProvisioningConfig'"
        $vmConfig = $vmConfig | Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUserName -Password $AdminPassword -EnableWinRMHttp #-Certificates $cert -WinRMCertificate (Get-LabAzureCertificate)
    
        if ($Machine.Disks)
        {
            Write-Verbose 'Adding disks'
            $container = Get-AzureStorageContainer -Name automatedlabdisks -ErrorAction Stop
            $lun = 0
        
            foreach ($disk in $Machine.Disks)
            {
                $vmConfig = $vmConfig | Add-AzureDataDisk -CreateNew -DiskLabel $disk.Name -DiskSizeInGB $disk.DiskSize -MediaLocation "$($container.CloudBlobContainer.Uri.AbsoluteUri)/$($disk.Name)" -LUN $lun
                $lun++
                Write-Verbose -Message "Calling 'Add-AzureDataDisk'"
            }
        }
    
        Write-ProgressIndicator
    
        #Set subnet and IP address for the default NIC
        Write-Verbose -Message "Setting subnet (for default NIC) to '$Subnet'"
        $vmConfig = $vmConfig | Set-AzureSubnet -SubnetNames $Subnet
    
        Write-Verbose -Message 'Determining default IP address'
        #Write-Verbose -Message "NetworkAdapters: $(@($Machine.NetworkAdapters).count)"
        #$Machine.NetworkAdapters
        #$defaultIPv4Address = @($Machine.NetworkAdapters)[0].Ipv4Address.AddressAsString
        $defaultIPv4Address = $DefaultIpAddress
        Write-Verbose -Message "Default IP address is '$DefaultIpAddress'"
        
        $vmConfig = $vmConfig | Set-AzureStaticVNetIP -IPAddress $defaultIPv4Address

        #Add any additional NICs to the VM configuration
        if ($Machine.NetworkAdapters.Count -gt 1)
        {
            throw New-Object System.NotImplementedException
            foreach ($adapter in ($Machine.NetworkAdapters | Where-Object Ipv4Address -ne $defaultIPv4Address))
            {
                if ($adapter.Ipv4Address.ToString() -ne $defaultIPv4Address)
                {
                    $adapterStartAddress = Get-NetworkRange -IPAddress ($adapter.Ipv4Address.AddressAsString) -SubnetMask ($adapter.Ipv4Address.Ipv4Prefix) | Select-Object -First 1
                    Write-Verbose -Message "adapterStartAddress = '$adapterStartAddress'"
                    $vNet = $LabVirtualNetworkDefinition | Where-Object { $_.AddressSpace.AddressAsString -eq $adapterStartAddress }
                    if ($vNet)
                    {
                        Write-Verbose -Message "Adding additional network adapter with Vnet '$($vNet.Name)' in subnet '$adapterStartAddress' with IP address '$($adapter.Ipv4Address.AddressAsString)'"
                        #$vmConfig = $vmConfig | Add-AzureNetworkInterfaceConfig -Name ($adapter.Ipv4Address.AddressAsString) -SubnetName $adapter. -StaticVNetIPAddress $adapter.Ipv4Address.AddressAsString
                    }
                    else
                    {
                        throw "Vnet could not be determined for network adapter with IP address of '$(Get-NetworkRange -IPAddress ($adapter.Ipv4Address.AddressAsString) -SubnetMask ($adapter.Ipv4Address.Ipv4Prefix)))'"
                    }
                }
            }
        }
    
        Write-Verbose -Message 'Adding non SSL endpoint'
        $vmConfig = $vmConfig | Add-AzureEndpoint -Name PowerShellHttp -Protocol tcp -LocalPort 5985
        Write-Verbose -Message "Calling 'New-AzureVM'"

        New-AzureVM -VMs $vmConfig –ServiceName $MachineServiceName -VNetName $Vnet -ErrorAction Stop

        $VerbosePreference = $bvp
    }

    #test if the machine creation jobs succeeded
    $jobs = Get-Job -Name CreateAzureVM*
    if ($jobs | Where-Object State -eq Failed)
    {
        $machinesFailedToCreate = ($jobs.Name | ForEach-Object { ($_ -split '\(|\)')[3] }) -join ', '
        throw "Failed to create the following Azure machines: $machinesFailedToCreate'. For further information take a loot at the background job's result (Get-Job, Receive-Job)"
    }

    Write-LogFunctionExit
}
#endregion New-LWAzureVM

#region Initialize-LWAzureVM
function Initialize-LWAzureVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$Machine
    )

    $initScript = {
        param(
            [Parameter(Mandatory = $true)]
            $MachineSettings
        )

        #region Region Settings Xml
        $regionSettings = @'
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">

 <!-- user list -->
 <gs:UserList>
	<gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
 </gs:UserList>

 <!-- GeoID -->
 <gs:LocationPreferences>
	<gs:GeoID Value="{1}"/>
 </gs:LocationPreferences>

 <!-- system locale -->
 <gs:SystemLocale Name="{0}"/>

<!-- user locale -->
 <gs:UserLocale>
	<gs:Locale Name="{0}" SetAsCurrent="true" ResetAllSettings="true"/>
 </gs:UserLocale>

</gs:GlobalizationServices>
'@
        #endregion

        $geoId = 94 #default is US

        $computerName = ($env:ComputerName).ToUpper()
        $tempFile = [System.IO.Path]::GetTempFileName()
        $regsettings = ($MachineSettings."$computerName")[1]
        Write-Verbose -Message "Regional Settings for $computerName`: $regsettings"
        $regionSettings -f ($MachineSettings."$computerName")[0], $geoId | Out-File -FilePath $tempFile
        $argument = 'intl.cpl,,/f:"{0}"' -f $tempFile
        control.exe $argument
        Start-Sleep -Seconds 1
        Remove-Item -Path $tempFile

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

        #Set Power Scheme to High Performance
        powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

        #set the time zone
        $timezone = ($MachineSettings."$computerName")[1]
        Write-Verbose -Message "Time zone for $computerName`: $regsettings"
        tzutil.exe /s $regsettings

        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager\oobe' /v DoNotOpenInitialConfigurationTasksAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager' /v DoNotOpenServerManagerAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v FilterAdministratorToken /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableLUA /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration

        #turn off the Windows firewall
        netsh.exe advfirewall set domain state off
        netsh.exe advfirewall set private state off
        netsh.exe advfirewall set public state off

        
        $disks = ($MachineSettings."$computerName")[2]
        Write-Verbose -Message "Disk count for $computerName`: $disks"
        if ([int]$disks -gt 0)
        {
            $diskpartCmd = 'LIST DISK'

            $disks = $diskpartCmd | diskpart.exe

            foreach ($line in $disks)
            {
                if ($line -match 'Disk (?<DiskNumber>\d) \s+(Online|Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) GB')
                {
                    $nextDriveLetter = [char[]](67..90) | 
                    Where-Object { (Get-WmiObject -Class Win32_LogicalDisk | 
                    Select-Object -ExpandProperty DeviceID) -notcontains "$($_):"} | 
                    Select-Object -First 1

                    $diskNumber = $Matches.DiskNumber

                    $diskpartCmd = "@
                        SELECT DISK $diskNumber
                        ATTRIBUTES DISK CLEAR READONLY
                        ONLINE DISK
                        CREATE PARTITION PRIMARY
                        ASSIGN LETTER=$nextDriveLetter
                        EXIT
                    @"
                    $diskpartCmd | diskpart.exe | Out-Null

                    Start-Sleep -Seconds 2

                    cmd.exe /c "echo y | format $($nextDriveLetter): /q /v:DataDisk$diskNumber"
                }
        
            }
        }
    }

    Write-LogFunctionEntry
    
    $lab = Get-Lab

    #test again if the machine creation jobs succeeded
    $jobs = Get-Job -Name CreateAzureVM*
    if ($jobs | Where-Object State -eq Failed)
    {
        $machinesFailedToCreate = ($jobs.Name | ForEach-Object { ($_ -split '\(|\)')[3] }) -join ', '
        throw "Failed to create the following Azure machines: $machinesFailedToCreate'. For further information take a loot at the background job's result (Get-Job, Receive-Job)"
    }

    Write-ScreenInfo -Message 'Waiting for all machines to be visible in Azure'
    while ((Get-AzureVM -WarningAction SilentlyContinue | Where-Object ServiceName -in (Get-LabAzureService).ServiceName | Where-Object Name -in $Machine.Name).Count -ne $Machine.Count)
    {        
        Start-Sleep -Seconds 10
        Write-Verbose 'Still waiting for all machines to be visible in Azure'
    }
    Write-ScreenInfo -Message "$($Machine.Count) new machine(s) has been created and now visible in Azure"
    Write-ScreenInfo -Message 'Waiting until all machines have a DNS name in Azure'
    while ((Get-LabMachine).AzureConnectionInfo.DnsName.Count -ne (Get-LabMachine).Count)
    {
        Start-Sleep -Seconds 10
        Write-ScreenInfo -Message 'Still waiting until all machines have a DNS name in Azure'
    }
    Write-ScreenInfo -Message "DNS names found: $((Get-LabMachine).AzureConnectionInfo.DnsName.Count)"

    #refresh the machine list to have also Azure meta date is available
    $Machine = Get-LabMachine -ComputerName $Machine
	
    #Point out first added machine as staging machine for staging Tools folder and alike
    $stagingMachine = $Machine[0]
    
    #copy AL tools to lab machine and optionally the tools folder
    Write-ScreenInfo -Message "Waiting for machine '$stagingMachine' to be accessible" -NoNewLine
    Wait-LabVM -ComputerName $stagingMachine -ProgressIndicator 15 -ErrorAction Stop
    
    $toolsDestination = "$($stagingMachine.ToolsPath)"
    if ($stagingMachine.ToolsPathDestination)
    {
        $toolsDestination = "$($stagingMachine.ToolsPathDestination)"
    }
    
    
    if ($Machine | Where-Object {$_.ToolsPath -ne ''})
    {
        #Compress all tools for all machines into one zip file
        $tempFolderPath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $tempFolderPath
        $tempFolderPath = "$tempFolderPath.tmp"
        
        New-Item -ItemType Directory -Path "$tempFolderPath.tmp" | Out-Null
        
        $tempFilePath = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $tempFilePath
        $tempFilePath = $tempFilePath -replace '\.tmp', '.zip'
        
        foreach ($m in $Machine)
        {
            New-Item -ItemType Directory -Path "$tempFolderPath\$($m.Name)" | Out-Null
            if ($m -ne $stagingMachine -and $m.ToolsPath -and $m.ToolsPath -eq $stagingMachine.ToolsPath)
            {
                New-Item -ItemType File -Path "$tempFolderPath\$($m.Name)\Replica-$($stagingMachine.Name)" | Out-Null
            }
            elseif ($m.ToolsPath)
            {
                Get-ChildItem -Path "$($m.ToolsPath)" | Copy-Item -Destination "$tempFolderPath\$($m.Name)" -Recurse
            }
        }   
        
        Write-Verbose -Message "Tools destination for staging machine: $($toolsDestination)"
        
        Add-Type -assembly 'system.io.compression.filesystem'
        [io.compression.zipfile]::CreateFromDirectory($tempFolderPath, $tempFilePath) 
        
        
        Write-ScreenInfo -Message "Starting copy of Tools ($([int]((Get-Item $tempfilepath).length/1kb)) KB) to staging machine '$stagingMachine'" -TaskStart
        Send-File -Source $tempFilePath -Destination C:\AutomatedLabTools.zip -Session (New-LabPSSession -ComputerName $stagingMachine)
        Write-ScreenInfo -Message 'Finished' -TaskEnd
        
        Remove-Item -Path $tempFilePath
        Remove-Item -Path $tempFolderPath -Recurse
        
        
        #Expand files on staging machine and create a share for other machines to access
        $job = Invoke-LabCommand -ComputerName $stagingMachine -ActivityName 'Expanding Tools Zip File' -NoDisplay -ArgumentList $toolsDestination -ScriptBlock `
        {
            param
            (
                [string]$ToolsDestination
            )
        
            if (-not (Test-Path 'C:\AutomatedLabTools'))
            {
                New-Item -ItemType Directory -Path 'C:\AutomatedLabTools' | Out-Null
            }

            if (-not (Test-Path $ToolsDestination))
            {
                New-Item -ItemType Directory -Path $ToolsDestination | Out-Null
            }
            
            $shell = New-Object -ComObject Shell.Application
            $shell.namespace('C:\AutomatedLabTools').CopyHere($shell.Namespace('C:\AutomatedLabTools.zip').Items()) 
            
            if (Test-Path "C:\AutomatedLabTools\$(Hostname.exe)")
            {
                Get-ChildItem -Path "C:\AutomatedLabTools\$(Hostname.exe)" | Copy-Item -Destination $ToolsDestination -Recurse
            }

            $shareClass = [WMICLASS]'WIN32_Share'
            $shareClass.Create('C:\AutomatedLabTools', 'AutomatedLabTools', 0)
        } -AsJob -PassThru
    
        Write-ScreenInfo -Message 'Waiting for Tools to be extracted on staging machine' -NoNewLine
        Wait-LWLabJob -Job $job -ProgressIndicator 5 -Timeout 30 -NoDisplay
    
    
        Write-ScreenInfo -Message 'Waiting for all machines to be accessible' -TaskStart -NoNewLine
        Write-Verbose "Staging machine is '$stagingMachine'"
        $otherMachines = Get-LabMachine | Where-Object Name -ne $stagingMachine
        #if the lab has not just one machine, wait for other machines
        if ($otherMachines)
        {
            Write-Verbose "Other machines are '$($otherMachines -join '. ')'"
            Wait-LabVM -ComputerName $otherMachines -ProgressIndicator 15 -ErrorAction Stop
        }
        Write-ScreenInfo -Message 'All machines are now accessible' -TaskEnd

        $jobs = Get-Job -Name NewAzureVNetGateway*
        if ($jobs)
        {
            Write-ScreenInfo -Message "Azure is creating gateways. This can take up to 45 minutes. There are $($jobs.Count) jobs still running"

            Wait-LWAzureGatewayJob

            Write-ScreenInfo 'Azure completed creating gateways'
        }

        Write-ScreenInfo -Message 'Configuring localization and additional disks' -TaskStart -NoNewLine
	    
        $machineSettings = @{}
        foreach ($m in $Machine)
        {
            $machineSettings.Add($m.Name.ToUpper(), @($m.UserLocale, $m.TimeZone, [int]($m.Disks.Count)))
        }
        $jobs = Invoke-LabCommand -ComputerName $Machine -ActivityName VmInit -ScriptBlock $initScript -UseLocalCredential -ArgumentList $machineSettings -NoDisplay -AsJob -PassThru
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 30 -NoDisplay
        Write-ScreenInfo -Message 'Finished' -TaskEnd
	    
	    
        Write-ScreenInfo -Message 'Starting copy of Tools content to all machines' -TaskStart
	    
        if ($otherMachines)
        {
            $jobs = Invoke-LabCommand -ComputerName $otherMachines -NoDisplay -AsJob -PassThru -ActivityName 'Copy tools from staged folder' -ScriptBlock `
            {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [string]$Server,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$User,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$Password,
                    
                    [string]$ToolsDestination
                )
                
                #Remove-Item -Path C:\Tools -Recurse
                $backupErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'SilentlyContinue'
                
                net.exe use * "\\$Server\AutomatedLabTools" /user:$Server\$User $Password | Out-Null
                $ErrorActionPreference = $backupErrorActionPreference
            
                write-host '3'
                if (Test-Path "\\$Server\AutomatedLabTools\$(Hostname.exe)\Replica-*")
                {
                    $source = (Get-Item "\\$Server\AutomatedLabTools\$(Hostname.exe)\Replica-*").Name.Split('-', 2)[1]
                    Copy-Item "\\$Server\AutomatedLabTools\$source" -Destination $ToolsDestination -Recurse
                }
                else
                {
                    Copy-Item "\\$Server\AutomatedLabTools\$(Hostname.exe)" -Destination $ToolsDestination -Recurse
                }
                $backupErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'SilentlyContinue'
                
                net.exe use "\\$Server\AutomatedLabTools" /delete /yes | Out-Null
                $ErrorActionPreference = $backupErrorActionPreference
                
            } -ArgumentList $stagingMachine.NetworkAdapters[0].Ipv4Address.IpAddress, $stagingMachine.InstallationUser.UserName, $stagingMachine.InstallationUser.Password, $toolsDestination
        }
    }
    Write-ScreenInfo -Message 'Finished' -TaskEnd
	
    Enable-LabVMRemoting -ComputerName $Machine
    
    Write-ScreenInfo -Message 'Stopping all new machines except domain controllers'
    $machinesToStop = $Machine | Where-Object { $_.Roles.Name -notcontains 'RootDC' -and $_.Roles.Name -notcontains 'FirstChildDC' -and $_.Roles.Name -notcontains 'DC' -and $_.IsDomainJoined }
    if ($machinesToStop)
    {
        Stop-LWAzureVM -ComputerName $machinesToStop
        Wait-LabVMShutdown -ComputerName $machinesToStop
    }
	
    if ($machinesToStop)
    {
        Write-ScreenInfo -Message "$($Machine.Count) new Azure machines was configured. Some machines were stopped as they are not to be domain controllers '$($machinesToStop -join ', ')'"
    }
    else
    {
        Write-ScreenInfo -Message "($($Machine.Count)) new Azure machines was configured"
    }
        
    Write-LogFunctionExit
}
#endregion Initialize-LWAzureVM

#region Remove-LWAzureVM
function Remove-LWAzureVM
{
    Param (
        [Parameter(Mandatory)]
        [string]$ComputerName,
		
        [switch]$AsJob,
		
        [switch]$PassThru
    )
	
    Write-LogFunctionEntry
	
    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            param (
                [Parameter(Mandatory)]
                [hashtable]$ComputerName
            )
			
            Import-Module -Name Azure
			
            $vm = Get-AzureVM -ServiceName ((Get-LabMachine -ComputerName $ComputerName).AzureConnectionInfo.ServiceName) -WarningAction SilentlyContinue | Where-Object Name -eq $ComputerName
			
            $vm | Remove-AzureVM -DeleteVHD
        } -ArgumentList $ComputerName
		
        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $vm = Get-AzureVM -ServiceName ((Get-LabMachine -ComputerName $ComputerName).AzureConnectionInfo.ServiceName) -WarningAction SilentlyContinue | Where-Object Name -eq $ComputerName
		
        $result = $vm | Remove-AzureVM -DeleteVHD
    }
	
    Write-LogFunctionExit
}
#endregion Remove-LWAzureVM

#region Start-LWAzureVM
function Start-LWAzureVM
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [int]$DelayBetweenComputers = 0,

        [int]$ProgressIndicator = 15,

        [switch]$NoNewLine
    )
	
    Write-LogFunctionEntry
	
    $azureVms = Get-AzureVM -WarningAction SilentlyContinue | 
        Where-Object { $_.Name -in $ComputerName -and $_.ServiceName -in ((Get-LabMachine -ComputerName $ComputerName).AzureConnectionInfo.ServiceName | 
        Select-Object -Unique)
    }

    $retries = 5
    $machinesToJoin = @()
	
    foreach ($name in $ComputerName)
    {
        $vm = $azureVms | Where-Object Name -eq $name

        do {
            $result = $vm | Start-AzureVM -ErrorAction SilentlyContinue
            if ($result.OperationStatus -ne 'Succeeded')
            {
                Start-Sleep -Seconds 10
            }
            $retries--
        }
        until ($retries -eq 0 -or $result.OperationStatus -eq 'Succeeded')
		
        if ($result.OperationStatus -ne 'Succeeded')
        {
            throw "Could not start machine '$name'"
        }
        else
        {
            $machine = Get-LabMachine -ComputerName $name
            #if the machine should be domain-joined but has not yet joined and is not a domain controller 
            if ($machine.IsDomainJoined -and -not $machine.HasDomainJoined -and ($machine.Roles.Name -notcontains 'RootDC' -and $machine.Roles.Name -notcontains 'FirstChildDC' -and $machine.Roles.Name -notcontains 'DC'))
            {
                $machinesToJoin += $machine
            }
        }

        Start-Sleep -Seconds $DelayBetweenComputers
    }

    if ($machinesToJoin)
    {
        Write-Verbose -Message "Waiting for machines '$($machinesToJoin -join ', ')' to come online"
        Wait-LabVM -ComputerName $machinesToJoin -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

        Write-Verbose -Message 'Start joining the machines to the respective domains'
        Join-LabVMDomain -Machine $machinesToJoin
    }
	
    Write-LogFunctionExit
}
#endregion Start-LWAzureVM

#region Stop-LWAzureVM
function Stop-LWAzureVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [switch]$ShutdownFromOperatingSystem = $true
    )
	
    Write-LogFunctionEntry
	
    $azureVms = Get-AzureVM -WarningAction SilentlyContinue | Where-Object {$_.Name -in $ComputerName -and $_.ServiceName -in ((Get-LabMachine -ComputerName $ComputerName).AzureConnectionInfo.ServiceName | Select-Object -Unique)}
	
    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $jobs = Invoke-LabCommand -ComputerName $ComputerName -NoDisplay -AsJob -PassThru -ScriptBlock { shutdown.exe -s -t 0 -f }
        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object {$_.State -eq 'Failed'}
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$($failedJobs.Location)'" -Type Error
        }
    }
    else
    {
        foreach ($name in $ComputerName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $result = $vm | Stop-AzureVM -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Force
            
            if ($result.OperationStatus -ne 'Succeeded')
            {
                Write-Error -Message 'Could not stop Azure VM' -TargetObject $name
            }
            else
            {
                #remove the AzureConnectionInfo if existing as ports may change if the machine starts again
                if ($vm.AzureConnectionInfo)
                {
                    $vm.AzureConnectionInfo = $null
                }
            }
            if ($ProgressIndicator -and (-not $NoNewLine))
            {
                Write-ProgressIndicator
            }
        }
    }
    
    if ($ProgressIndicator -and (-not $NoNewLine))
    {
        Write-ProgressIndicatorEnd
    }
	
    Write-LogFunctionExit
}

#endregion Stop-LWAzureVM

#region Wait-LWAzureRestartVM
function Wait-LWAzureRestartVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
		
        [double]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	
    Write-LogFunctionEntry
	
    $start = (Get-Date).ToUniversalTime()
	
    Write-Verbose -Message "Starting monitoring the servers at '$start'"
	
    $machines = Get-LabMachine -ComputerName $ComputerName
	
    $cmd = {
        param (
            [datetime]$Start
        )
		
        $Start = $Start.ToLocalTime()

        $events = Get-EventLog -LogName System -InstanceId 2147489653 -After $Start -Before $Start.AddMinutes(40)
		
        $events
    }
	
    $ProgressIndicatorTimer = (Get-Date)

    do
    {
        $machines = foreach ($machine in $machines)
        {
            if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
            {
                Write-ProgressIndicator
                $ProgressIndicatorTimer = (Get-Date)
            }
            
            $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -UseLocalCredential -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if (-not $events)
            {
                $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
			
            if ($events)
            {
                Write-Verbose -Message "VM '$machine' has been restarted"
            }
            else
            {
                $machine
            }
        }
    }
    until ($machines.Count -eq 0 -or (Get-Date).ToUniversalTime().AddMinutes(-$TimeoutInMinutes) -gt $start)
	
    if (-not $NoNewLine)
    {
        Write-ProgressIndicatorEnd
    }
    
    if ((Get-Date).ToUniversalTime().AddMinutes(-$TimeoutInMinutes) -gt $start)
    {
        foreach ($machine in ($machines))
        {
            Write-Error -Message "Timeout while waiting for computers to restart. Computers '$machine' not restarted" -TargetObject $machine
        }
    }
    
    Write-Verbose -Message "Finished monitoring the servers at '$(Get-Date)'"
	
    Write-LogFunctionExit
}
#endregion Wait-LWAzureRestartVM

#region Get-LWAzureVMStatus
function Get-LWAzureVMStatus
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	
    Write-LogFunctionEntry
	
    $result = @{ }
    $azureVms = Get-AzureVM -WarningAction SilentlyContinue | Where-Object {$_.Name -in $ComputerName -and $_.ServiceName -in ((Get-LabMachine).AzureConnectionInfo.ServiceName | Select-Object -Unique)}
    
	
    foreach ($azureVm in $azureVms)
    {
        if ($azureVm.InstanceStatus -eq 'ReadyRole')
        {
            $result.Add($azureVm.Name, 'Started')
        }
        elseif ($azureVm.InstanceStatus -eq 'StoppedVM' -or $azureVm.InstanceStatus -eq 'StoppedDeallocated')
        {
            $result.Add($azureVm.Name, 'Stopped')
        }
        else
        {
            $result.Add($azureVm.Name, 'Unknown')
        }
    }
	
    $result
	
    Write-LogFunctionExit
}
#endregion Get-LWAzureVMStatus

#region Get-LWAzureVMConnectionInfo
function Get-LWAzureVMConnectionInfo
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )
	
    Write-LogFunctionEntry

    $azureVMs = Get-AzureVM -WarningAction SilentlyContinue | Where-Object ServiceName -in (Get-LabAzureService).ServiceName | Where-Object Name -in $ComputerName
	
    foreach ($name in $ComputerName)
    {
        $azureVM = $azureVMs | Where-Object Name -eq $name

        if (-not $azureVM)
        { return }

        $endpoint = $azureVM | Get-AzureEndpoint -Name PowerShellHTTP
        $endpointRdp = $azureVM | Get-AzureEndpoint -Name RemoteDesktop
	
        $dnsName = if ($azureVM.DNSName) { $azureVM.DNSName.Substring(7, ($azureVM.DNSName.Length - 8)) }

        New-Object PSObject -Property @{
            ComputerName = $name
            DnsName = $dnsName
            HttpsName = $azureVM.DNSName
            VIP = $endpoint.Vip
            Port = $endpoint.Port
            RdpPort = $endpointRdp.Port
            ServiceName = $azureVM.ServiceName
        }
    }
	
    Write-LogFunctionExit
}
#endregion Get-LWAzureVMConnectionInfo

#region Enable-LWAzureVMRemoting
function Enable-LWAzureVMRemoting
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        [switch]$UseSSL
    )

    if ($ComputerName)
    {
        $machines = Get-LabMachine -All | Where-Object Name -in $ComputerName
    }
    else
    {
        $machines = Get-LabMachine -All
    }
	
    $script = {
        param ($DomainName, $UserName, $Password)
		
        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
		
        Set-ItemProperty -Path $RegPath -Name AutoAdminLogon -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultUserName -Value $UserName -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultPassword -Value $Password -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $RegPath -Name DefaultDomainName -Value $DomainName -ErrorAction SilentlyContinue
		
        #Enable-WSManCredSSP works fine when called remotely on 2012 servers but not on 2008 (Access Denied). In case Enable-WSManCredSSP fails
        #the settings are done in the registry directly
        try
        {
            Enable-WSManCredSSP -Role Server -Force | Out-Null
        }
        catch
        {
            New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name auth_credssp -Value 1 -PropertyType DWORD -Force
            New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name allow_remote_requests -Value 1 -PropertyType DWORD -Force
        }
    }
	
    foreach ($machine in $machines)
    {
        $cred = $machine.GetCredential((Get-Lab))
        try
        {
            Invoke-LabCommand -ComputerName $machine -ActivityName SetLabVMRemoting -NoDisplay -ScriptBlock $script `
            -ArgumentList $machine.DomainName, $cred.UserName, $cred.GetNetworkCredential().Password -ErrorAction Stop
        }
        catch
        {
            if ($UseSSL)
            {
                Connect-WSMan -ComputerName $machine.AzureConnectionInfo.DnsName -Credential $cred -Port $machine.AzureConnectionInfo.Port -UseSSL -SessionOption (New-WSManSessionOption -SkipCACheck -SkipCNCheck)
            }
            else
            {
                Connect-WSMan -ComputerName $machine.AzureConnectionInfo.DnsName -Credential $cred -Port $machine.AzureConnectionInfo.Port
            }
            Set-Item -Path "WSMan:\$($machine.AzureConnectionInfo.DnsName)\Service\Auth\CredSSP" -Value $true
            Disconnect-WSMan -ComputerName $machine.AzureConnectionInfo.DnsName
        }
    }
}
#endregion Enable-LWAzureVMRemoting