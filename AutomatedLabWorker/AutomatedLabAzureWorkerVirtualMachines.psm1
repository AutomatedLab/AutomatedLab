$azureRetryCount = (Get-Module -ListAvailable -Name AutomatedLabWorker)[0].PrivateData.AzureRetryCount

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
    
    $resourceGroupName = $lab.Name
    if ($machine.AzureProperties)
    {
        if ($machine.AzureProperties.ContainsKey('ResourceGroupName'))
        {
            #if the resource group name is provided for the machine, it replaces the default
            $resourceGroupName = $machine.AzureProperties.ResourceGroupName
        }
    }
    
    $machineResourceGroup = $Machine.AzureProperties.ResourceGroupName
    if (-not $machineResourceGroup)
    {
        $machineResourceGroup = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    }

    if (Get-AzureRmVM -Name $machine.Name -ResourceGroupName $machineResourceGroup -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
    {
        Write-Verbose -Message "Target machine $($Machine.Name) already exists. Skipping..."
        return
    }
    
    Write-Verbose -Message "Target resource group for machine: '$machineResourceGroup'"
    
    if (-not $global:cacheVMs)
    {
        $global:cacheVMs = Get-AzureRmVM -WarningAction SilentlyContinue
    }

    if ($global:cacheVMs | Where-Object { $_.Name -eq $Machine.Name -and $_.ResourceGroupName -eq $resourceGroupName })
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "Machine '$($machine.name)' already exist. Skipping creation of this machine" -Type Warning
        return
    }

    Write-Verbose -Message "Creating container 'automatedlabdisks' for additional disks"
    $storageContext = (Get-AzureRmStorageAccount -Name $lab.AzureSettings.DefaultStorageAccount -ResourceGroupName $machineResourceGroup -ErrorAction SilentlyContinue).Context

    if (-not $storageContext)
    {
        $storageContext = (Get-AzureRmStorageAccount -Name $lab.AzureSettings.DefaultStorageAccount -ResourceGroupName $machineResourceGroup -ErrorAction Stop).Context
    }

    $container = Get-AzureStorageContainer -Name automatedlabdisks -Context $storageContext -ErrorAction SilentlyContinue
    if (-not $container)
    {
        $container = New-AzureStorageContainer -Name automatedlabdisks -Context $storageContext
    }

    Write-Verbose -Message "Scheduling creation Azure machine '$Machine'"

    #random number in the path to prevent conflicts
    $rnd = (Get-Random -Minimum 1 -Maximum 1000).ToString('0000')
    $osVhdLocation = "$($storageContext.BlobEndpoint)/automatedlab1/$($machine.Name)OsDisk$rnd.vhd"
    $lab.AzureSettings.VmDisks.Add($osVhdLocation)
    Write-Verbose -Message "The location of the VM disk is '$osVhdLocation'"

    $adminUserName = $Machine.InstallationUser.UserName
    $adminPassword = $Machine.InstallationUser.Password
    
    #if this machine has a SQL Server role
    foreach ($role in $Machine.Roles) 
    { 
        if ($role.Name -match 'SQLServer(?<SqlVersion>\d{4})')
        {
            #get the SQL Server version defined in the role
            $sqlServerRoleName = $Matches[0]
            $sqlServerVersion = $Matches.SqlVersion
           
            if ($role.Properties.Keys | Where-Object {$_ -ne 'InstallSampleDatabase'})
            {
                $useStandardVm = $true
            }
        }  
        if ($role.Name -match 'VisualStudio(?<Version>\d{4})')
        {
            $visualStudioRoleName = $Matches[0]        
            $visualStudioVersion = $Matches.Version
        }
    
        if ($role.Name -match 'SharePoint(?<Version>\d{4})')
        {
            $sharePointRoleName = $Matches[0]
            $sharePointVersion = $Matches.Version
        }
    }
                
    if ($sqlServerRoleName -and -not $useStandardVm)
    {
        Write-Verbose -Message 'This is going to be a SQL Server VM'
        $pattern = 'SQL(?<SqlVersion>\d{4})(?<SqlIsR2>R2)??(?<SqlServicePack>SP\d)?-(?<OS>WS\d{4}(R2)?)'
                
        #get all SQL images matching the RegEx pattern and then get only the latest one
        $sqlServerImages = $lab.AzureSettings.VmImages | Where-Object Offer -notlike "*BYOL*"

        if ([System.Convert]::ToBoolean($Machine.AzureProperties['UseByolImage']))
        {
            $sqlServerImages = $lab.AzureSettings.VmImages | Where-Object Offer -like '*-BYOL'
        }

        $sqlServerImages = $sqlServerImages |
            Where-Object Offer -Match $pattern | 
            Group-Object -Property Sku, Offer | 
            ForEach-Object {
            $_.Group | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1
        }

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($sqlServerImage in $sqlServerImages)
        {
            $sqlServerImage.Offer -match $pattern | Out-Null

            $sqlServerImage | Add-Member -Name SqlVersion -Value $Matches.SqlVersion -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlIsR2 -Value $Matches.SqlIsR2 -MemberType NoteProperty -Force
            $sqlServerImage | Add-Member -Name SqlServicePack -Value $Matches.SqlServicePack -MemberType NoteProperty -Force
    
            $sqlServerImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImage = $sqlServerImages | Where-Object { $_.SqlVersion -eq $sqlServerVersion -and $_.OS.Version -eq $machineOs.Version } |
            Sort-Object -Property SqlServicePack -Descending | Select-Object -First 1
        $offerName = $vmImageName = $vmImage | Select-Object -ExpandProperty Offer
        $publisherName = $vmImage | Select-Object -ExpandProperty PublisherName
        $skusName = $vmImage | Select-Object -ExpandProperty Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'SQL Server image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($sqlServerImage in $sqlServerImages)
            {
                Write-Host $sqlServerImage.Offer
            }

            throw "There is no Azure VM image for '$sqlServerRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($visualStudioRoleName)
    {
        Write-Verbose -Message 'This is going to be a Visual Studio VM'

        $pattern = 'VS-(?<Version>\d{4})-(?<Edition>\w+)-VSU(?<Update>\d)-AzureSDK-\d{2,3}-((?<OS>WIN\d{2})|(?<OS>WS\d{4,6}))'
                
        #get all SQL images machting the RegEx pattern and then get only the latest one
        $visualStudioImages = $lab.AzureSettings.VmImages |
            Where-Object Offer -EQ VisualStudio

        #add the version, SP Level and OS from the ImageFamily field to the image object
        foreach ($visualStudioImage in $visualStudioImages)
        {
            $visualStudioImage.Skus -match $pattern | Out-Null

            $visualStudioImage | Add-Member -Name Version -Value $Matches.Version -MemberType NoteProperty -Force
            $visualStudioImage | Add-Member -Name Update -Value $Matches.Update -MemberType NoteProperty -Force
    
            $visualStudioImage | Add-Member -Name OS -Value (New-Object AutomatedLab.OperatingSystem($Matches.OS)) -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        $vmImage = $visualStudioImages | Where-Object { $_.Version -eq $visualStudioVersion -and $_.OS.Version.Major -eq $machineOs.Version.Major } |
            Sort-Object -Property Update -Descending | Select-Object -First 1
        $offerName = $vmImageName = $vmImage | Select-Object -ExpandProperty Offer
        $publisherName = $vmImage | Select-Object -ExpandProperty PublisherName
        $skusName = $vmImage | Select-Object -ExpandProperty Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'Visual Studio image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($visualStudioImage in $visualStudioImages)
            {
                Write-ScreenInfo ('{0} - {1} - {2}' -f $visualStudioImage.Offer, $visualStudioImage.Skus, $visualStudioImage.Id)
            }

            throw "There is no Azure VM image for '$visualStudioRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($sharePointRoleName)
    {
        Write-Verbose -Message 'This is going to be a SharePoint VM'

        # AzureRM currently has only one SharePoint offer

        $sharePointRoleName -match '\w+(?<Version>\d{4})'
        
        $sharePointImages = $lab.AzureSettings.VmImages |
            Where-Object Offer -Match 'MicrosoftSharePoint' |
            Sort-Object -Property PublishedDate -Descending |
            Where-Object Skus -eq $Matches.Version |
            Select-Object -First 1

        # Add the SP version
        foreach ($sharePointImage in $sharePointImages)
        {
            $sharePointImage | Add-Member -Name Version -Value $sharePointImage.Skus -MemberType NoteProperty -Force
        }

        #get the image that matches the OS and SQL server version
        $machineOs = New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)
        Write-ScreenInfo "The SharePoint 2013 Trial image in Azure does not have any information about the OS anymore, hence this operating system specified is ignored. There is only $($sharePointImages.Count) image available." -Type Warning
        
        #$vmImageName = $sharePointImages | Where-Object { $_.Version -eq $sharePointVersion -and $_.OS.Version -eq $machineOs.Version } |
        $vmImage = $sharePointImages | Where-Object Version -eq $sharePointVersion |
            Sort-Object -Property Update -Descending | Select-Object -First 1

        $offerName = $vmImageName = $vmImage | Select-Object -ExpandProperty Offer
        $publisherName = $vmImage | Select-Object -ExpandProperty PublisherName
        $skusName = $vmImage | Select-Object -ExpandProperty Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'SharePoint image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($sharePointImage in $sharePointImages)
            {
                Write-Host $sharePointImage.Offer $sharePointImage.Skus
            }

            throw "There is no Azure VM image for '$sharePointRoleName' on operating system '$($Machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    else
    {
        $vmImageName = (New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)).AzureImageName
        if (-not $vmImageName)
        {
            throw "There is no Azure VM image for the operating system '$($Machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup."
        }

        $vmImage = $lab.AzureSettings.VmImages |
            Where-Object Skus -eq $vmImageName  |
            Select-Object -First 1

        $offerName = $vmImageName = $vmImage | Select-Object -ExpandProperty Offer
        $publisherName = $vmImage | Select-Object -ExpandProperty PublisherName
        $skusName = $vmImage | Select-Object -ExpandProperty Skus
    }
    Write-Verbose -Message "We selected the SKUs $skusName from offer $offerName by publisher $publisherName"
    
    Write-ProgressIndicator
    
    if ($machine.AzureProperties.RoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
            Where-Object { $_.Name -eq $machine.AzureProperties.RoleSize }
        Write-Verbose -Message "Using specified role size of '$($roleSize.Name)'"
    }
    elseif ($machine.AzureProperties.UseAllRoleSizes)
    {
        $DefaultAzureRoleSize = $MyInvocation.MyCommand.Module.PrivateData.DefaultAzureRoleSize
        $roleSize = $lab.AzureSettings.RoleSizes |
            Where-Object { $_.MemoryInMB -ge $machine.Memory -and $_.NumberOfCores -ge $machine.Processors -and $machine.Disks.Count -le $_.MaxDataDiskCount } |
            Sort-Object -Property MemoryInMB, NumberOfCores |
            Select-Object -First 1

        Write-Verbose -Message "Using specified role size of '$($roleSize.InstanceSize)'. VM was configured to all role sizes but constrained to role size '$DefaultAzureRoleSize' by psd1 file"
    }
    else
    {
        switch ($lab.AzureSettings.DefaultRoleSize)
        {
            'A' { $pattern = '^(Standard_A\d{1,2}|Basic_A\d{1,2})' }
            'D' { $pattern = '^Standard_D\d{1,2}' }
            'DS' { $pattern = '^Standard_DS\d{1,2}' }
            'G' { $pattern = '^Standard_G\d{1,2}' }
            'F' { $pattern = '^Standard_F\d{1,2}' }
            default { $pattern = '^(Standard_A\d{1,2}|Basic_A\d{1,2})'}
        }
        
        $roleSize = $lab.AzureSettings.RoleSizes |
            Where-Object { $_.Name -Match $pattern -and $_.Name -notlike '*promo*'} |
            Where-Object { $_.MemoryInMB -ge ($machine.Memory / 1MB) -and $_.NumberOfCores -ge $machine.Processors } |
            Sort-Object -Property MemoryInMB, NumberOfCores, @{ Expression = { if ($_.Name -match '.+_v(?<Version>\d{1,2})') { $Matches.Version } }; Ascending = $false } |
            Select-Object -First 1

        Write-Verbose -Message "Using specified role size of '$($roleSize.Name)' out of role sizes '$pattern'"
    }
    
    if (-not $roleSize)
    {
        throw "Could not find an appropriate role size in Azure $($machine.Processors) cores and $($machine.Memory) MB of memory"
    }
    
    Write-ProgressIndicator
    
    $labVirtualNetworkDefinition = Get-LabVirtualNetworkDefinition

    # List-serialization issues when passing to job. Disks will be added to a hashtable
    $Disks = @{}
    $Machine.Disks | ForEach-Object { $Disks.Add($_.Name, $_.DiskSize) }

    $Vnet = $Machine.NetworkAdapters[0].VirtualSwitch.Name
    $Location = $lab.AzureSettings.DefaultLocation.DisplayName
    $DefaultIpAddress = $Machine.NetworkAdapters[0].Ipv4Address.IpAddress

    Write-Verbose '-------------------------------------------------------'
    Write-Verbose "Machine: $($Machine.name)"
    Write-Verbose "Vnet: $Vnet"
    Write-Verbose "RoleSize: $RoleSize"
    Write-Verbose "VmImageName: $VmImageName"
    Write-Verbose "OsVhdLocation: $OsVhdLocation"
    Write-Verbose "AdminUserName: $AdminUserName"
    Write-Verbose "AdminPassword: $AdminPassword"
    Write-Verbose "ResourceGroupName: $ResourceGroupName"
    Write-Verbose "StorageAccountName: $($StorageContext.StorageAccountName)"
    Write-Verbose "BlobEndpoint: $($StorageContext.BlobEndpoint)"
    Write-Verbose "DefaultIpAddress: $DefaultIpAddress"
    Write-Verbose "Location: $Location"
    Write-Verbose "Lab name: $LabName"
    Write-Verbose "Publisher: $PublisherName"
    Write-Verbose "Offer: $OfferName"
    Write-Verbose "Skus: $SkusName"
    Write-Verbose '-------------------------------------------------------'
    
    $subnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName |
        Get-AzureRmVirtualNetworkSubnetConfig |
        Where-Object { $_.AddressPrefix -eq $Machine.IpAddress[0].ToString()}
        
    if (-not $subnet)
    {
        throw 'No subnet configuration found to fit machine in! Review the IP address of your machine and your lab virtual network.'
    }
    Write-Verbose -Message "Subnet for the VM is '$($subnet.Name)'"
        
    Write-Verbose -Message "Calling 'New-AzureVMConfig'"
                                     
    $cred = New-Object -TypeName pscredential -ArgumentList $adminUserName, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

    $machineAvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -ErrorAction SilentlyContinue
    if (-not ($machineAvailabilitySet))
    {
        $machineAvailabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -Location $Location -ErrorAction Stop	
    }

    $vm = New-AzureRmVMConfig -VMName $Machine.Name -VMSize $RoleSize -AvailabilitySetId $machineAvailabilitySet.Id  -ErrorAction Stop -WarningAction SilentlyContinue
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $Machine.Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -ErrorAction Stop -WinRMHttp
                           
    Write-Verbose "Choosing latest source image for $SkusName in $OfferName"
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $OfferName -Skus $SkusName -Version "latest" -ErrorAction Stop -WarningAction SilentlyContinue

    Write-Verbose -Message "Setting private IP address."
    $defaultIPv4Address = $DefaultIpAddress

    Write-Verbose -Message "Default IP address is '$DefaultIpAddress'."

    Write-Verbose -Message 'Locating load balancer and assigning NIC to appropriate rules and pool'
    $LoadBalancer = Get-AzureRmLoadBalancer -Name "$($ResourceGroupName)$($machine.Network)loadbalancer" -ResourceGroupName $resourceGroupName -ErrorAction Stop		
        
    $inboundNatRules = @(Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.Name.ToLower())rdpin" -ErrorAction SilentlyContinue)
    $inboundNatRules += Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.Name.ToLower())winrmin" -ErrorAction SilentlyContinue
    $inboundNatRules += Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.Name.ToLower())winrmhttpsin" -ErrorAction SilentlyContinue

    $nicProperties = @{
        Name                           = "$($Machine.Name.ToLower())nic0"
        ResourceGroupName              = $ResourceGroupName
        Location                       = $Location
        Subnet                         = $subnet
        PrivateIpAddress               = $defaultIPv4Address
        LoadBalancerBackendAddressPool = $LoadBalancer.BackendAddressPools[0]
        LoadBalancerInboundNatRule     = $inboundNatRules
        ErrorAction                    = 'Stop'
        WarningAction                  = 'SilentlyContinue'
        Force                          = $true
    }
        
    Write-Verbose -Message "Creating new network interface with configured private and public IP and subnet $($subnet.Name)"
    $networkInterface = New-AzureRmNetworkInterface @nicProperties
        
    Write-Verbose -Message 'Adding NIC to VM'
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop -WarningAction SilentlyContinue
        
                                   
    $DiskName = "$($machine.Name)_os"
    $OSDiskUri = "$($StorageContext.BlobEndpoint)automatedlabdisks/$DiskName.vhd"
        
    Write-Verbose "Adding OS disk to VM with blob url $OSDiskUri"
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $DiskName -VhdUri $OSDiskUri -CreateOption fromImage -ErrorAction Stop -WarningAction SilentlyContinue

    if ($Disks)
    {
        Write-Verbose "Adding $($Disks.Count) data disks"
        $lun = 0
        
        foreach ($Disk in $Disks.GetEnumerator())
        {
            $DataDiskName = $Disk.Key.ToLower()
            $DiskSize = $Disk.Value
            $VhdUri = "$($StorageContext.BlobEndpoint)automatedlabdisks/$DataDiskName.vhd"

            Write-Verbose -Message "Calling 'Add-AzureRmVMDataDisk' for $DataDiskName with $DiskSize GB on LUN $lun (resulting in uri $VhdUri)"
            $vm = $vm | Add-AzureRmVMDataDisk -Name $DataDiskName -VhdUri $VhdUri -Caching None -DiskSizeInGB $DiskSize -Lun $lun -CreateOption Empty				
            $lun++
        }
    }
           
    Write-ProgressIndicator        

    #Add any additional NICs to the VM configuration
    if ($Machine.NetworkAdapters.Count -gt 1)
    {
        Write-Verbose -Message "Adding $($Machine.NetworkAdapters.Count) additional NICs to the VM config"
        foreach ($adapter in ($Machine.NetworkAdapters | Where-Object Ipv4Address -ne $defaultIPv4Address))
        {
            if ($adapter.Ipv4Address.ToString() -eq $defaultIPv4Address) {continue}

            $adapterStartAddress = Get-NetworkRange -IPAddress ($adapter.Ipv4Address.AddressAsString) -SubnetMask ($adapter.Ipv4Address.Ipv4Prefix) | Select-Object -First 1
            $additionalSubnet = (Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName | Where-Object { $_.AddressSpace.AddressPrefixes.Contains($adapterStartAddress) })[0] |
                Get-AzureRmVirtualNetworkSubnetConfig
        
            Write-Verbose -Message "adapterStartAddress = '$adapterStartAddress'"
            $vNet = $LabVirtualNetworkDefinition | Where-Object { $_.AddressSpace.AddressAsString -eq $adapterStartAddress }
            if (-not $vNet)
            {
                Write-Error -Message "Vnet could not be determined for network adapter with IP address of '$(Get-NetworkRange -IPAddress ($adapter.Ipv4Address.AddressAsString) -SubnetMask ($adapter.Ipv4Address.Ipv4Prefix)))'"
            }
            
            Write-Verbose -Message "Adding additional network adapter with Vnet '$($vNet.Name)' in subnet '$adapterStartAddress' with IP address '$($adapter.Ipv4Address.AddressAsString)'"
            $additionalNicParameters = @{
                Name              = ($adapter.Ipv4Address.AddressAsString)
                ResourceGroupName = $ResourceGroupName
                Location          = $Location
                Subnet            = $additionalSubnet
                PrivateIpAddress  = ($adapter.Ipv4Address.AddressAsString)
                Force             = $true
            }

            $networkInterface = New-AzureRmNetworkInterface @additionalNicParameters        
            $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop -WarningAction SilentlyContinue
        }
    }

    Write-Verbose -Message 'Calling New-AzureRMVm'
            
    $vmParameters = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
        VM                = $vm
        Tag               = @{ AutomatedLab = $script:lab.Name; CreationTime = Get-Date }
        ErrorAction       = 'Stop'
        WarningAction     = 'SilentlyContinue'
        AsJob             = $true
    }

    New-AzureRmVM @vmParameters
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
        
        #Create a scheduled tasks that maps the Azure lab sources drive during each logon
        $labSourcesStorageAccount = ($MachineSettings."$computerName")[3]
        
        $script = @'    
    $labSourcesPath = '{0}'

    $pattern = '^(OK|Unavailable) +(?<DriveLetter>\w): +\\\\automatedlab'

    #remove all drive connected to an Azure LabSources share that are no longer available
    $drives = net.exe use
    foreach ($line in $drives)
    {{
        if ($line -match $pattern)
        {{
            net.exe use "$($Matches.DriveLetter):" /d
        }}
    }}

    cmdkey.exe /add:{1} /user:{2} /pass:{3}

    Start-Sleep -Seconds 1

    net.exe use * {0} /u:{2} {3}
'@

        $cmdkeyTarget = ($labSourcesStorageAccount.Path -split '\\')[2]
        $script = $script -f $labSourcesStorageAccount.Path, $cmdkeyTarget, $labSourcesStorageAccount.StorageAccountName, $labSourcesStorageAccount.StorageAccountKey

        mkdir -Path C:\AL -Force
        $labSourcesStorageAccount | Export-Clixml -Path C:\AL\LabSourcesStorageAccount.xml
        $script | Out-File C:\AL\AzureLabSources.ps1 -Force
        
        SCHTASKS /Create /SC ONCE /ST 00:00 /TN ALLabSourcesCmdKey /TR "powershell.exe -File C:\AL\AzureLabSources.ps1" /RU "NT AUTHORITY\SYSTEM"

        #set the time zone
        $timezone = ($MachineSettings."$computerName")[1]
        Write-Verbose -Message "Time zone for $computerName`: $regsettings"
        tzutil.exe /s $regsettings

        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v ALLabSourcesCmdKey /d 'powershell.exe -File C:\AL\AzureLabSources.ps1' /t REG_SZ /f
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
        
        if (($MachineSettings."$computerName")[6])
        {
            $dnsServers = ($MachineSettings."$computerName")[6]
            Write-Verbose "Configuring $($dnsServers.Count) DNS Servers"
            $idx = (Get-NetIPInterface | Where-object {$_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*"}).ifIndex
            Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $dnsServers
        }
        
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

    Write-ScreenInfo -Message 'Waiting for all machines to be visible in Azure'
    while ((Get-AzureRmVM -ResourceGroupName $lab.Name -WarningAction SilentlyContinue | Where-Object Name -in $Machine.Name).Count -ne $Machine.Count)
    {        
        Start-Sleep -Seconds 10
        Write-Verbose 'Still waiting for all machines to be visible in Azure'
    }
    Write-ScreenInfo -Message "$($Machine.Count) new machine(s) has been created and now visible in Azure"
    Write-ScreenInfo -Message 'Waiting until all machines have a DNS name in Azure'
    while ((Get-LabVM).AzureConnectionInfo.DnsName.Count -ne (Get-LabVM).Count)
    {
        Start-Sleep -Seconds 10
        Write-ScreenInfo -Message 'Still waiting until all machines have a DNS name in Azure'
    }
    Write-ScreenInfo -Message "DNS names found: $((Get-LabVM).AzureConnectionInfo.DnsName.Count)"

    #refresh the machine list to make sure Azure connection info is available
    $Machine = Get-LabVM -ComputerName $Machine
      
    #copy AL tools to lab machine and optionally the tools folder
    Write-ScreenInfo -Message "Waiting for machines '$($Machine -join ', ')' to be accessible" -NoNewLine
    Wait-LabVM -ComputerName $Machine -ProgressIndicator 15 -DoNotUseCredSsp -ErrorAction Stop

    Write-ScreenInfo -Message 'Configuring localization and additional disks' -TaskStart -NoNewLine
    $machineSettings = @{}
    $lab = Get-Lab
    foreach ($m in $Machine)
    {
        [string[]]$DnsServers = ($m.NetworkAdapters | Where-Object {$_.VirtualSwitch.Name -eq $Lab.Name}).Ipv4DnsServers.AddressAsString
        $machineSettings.Add($m.Name.ToUpper(),
            @(
                $m.UserLocale,
                $m.TimeZone,
                [int]($m.Disks.Count),
                (Get-LabAzureLabSourcesStorage),
                $DnsServers,
                $Machine.GetLocalCredential()
            )
        )
    }
    $jobs = Invoke-LabCommand -ComputerName $Machine -ActivityName VmInit -ScriptBlock $initScript -UseLocalCredential -ArgumentList $machineSettings -DoNotUseCredSsp -AsJob -PassThru -NoDisplay
    Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 30 -NoDisplay
    Write-ScreenInfo -Message 'Finished' -TaskEnd
    
    Enable-LabVMRemoting -ComputerName $Machine
    
    Write-ScreenInfo -Message 'Stopping all new machines except domain controllers'
    $machinesToStop = $Machine | Where-Object { $_.Roles.Name -notcontains 'RootDC' -and $_.Roles.Name -notcontains 'FirstChildDC' -and $_.Roles.Name -notcontains 'DC' -and $_.IsDomainJoined }
    if ($machinesToStop)
    {
        Stop-LWAzureVM -ComputerName $machinesToStop -StayProvisioned $true
        Wait-LabVMShutdown -ComputerName $machinesToStop
    }
    
    if ($machinesToStop)
    {
        Write-ScreenInfo -Message "$($Machine.Count) new Azure machines were configured. Some machines were stopped as they are not to be domain controllers '$($machinesToStop -join ', ')'"
    }
    else
    {
        Write-ScreenInfo -Message "($($Machine.Count)) new Azure machines were configured"
    }

    Write-Verbose "Removing all sessions after VmInit"
    Remove-LabPSSession
        
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

    $Lab = Get-Lab
    
    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            param (
                [Parameter(Mandatory)]
                [hashtable]$ComputerName
            )
            
            $resourceGroup = ((Get-LabVM -ComputerName $ComputerName).AzureConnectionInfo.ResourceGroupName)

            $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $ComputerName -WarningAction SilentlyContinue
            
            $vm | Remove-AzureRmVM -Force
        } -ArgumentList $ComputerName
        
        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $resourceGroup = ((Get-LabVM -ComputerName $ComputerName).AzureConnectionInfo.ResourceGroupName)
        $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $ComputerName -WarningAction SilentlyContinue
        
        $result = $vm | Remove-AzureRmVM -Force
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
    
    $azureVms = Get-AzureRmVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if (-not $azureVms)
    {
        Start-Sleep -Seconds 2
        $azureVms = Get-AzureRmVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $azureVms)
        {
            throw 'Get-AzureRmVM did not return anything, stopping lab deployment. Code will be added to handle this error soon'
        }
    }

    $azureVms = $azureVms | Where-Object { $_.PowerState -ne 'VM running' -and $_.Name -in $ComputerName}

    $lab = Get-Lab

    $machinesToJoin = @()

    $jobs = foreach ($name in $ComputerName)
    {
        $vm = $azureVms | Where-Object Name -eq $name			
        $vm | Start-AzureRmVM -AsJob
    }

    Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator

    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName}

    foreach ($name in $ComputerName)
    {
        $vm = $azureVms | Where-Object Name -eq $name
                
        if (-not $vm.PowerState -eq 'VM Running')
        {
            throw "Could not start machine '$name'"
        }
        else
        {
            $machine = Get-LabVM -ComputerName $name
            #if the machine should be domain-joined but has not yet joined and is not a domain controller 
            if ($machine.IsDomainJoined -and -not $machine.HasDomainJoined -and ($machine.Roles.Name -notcontains 'RootDC' -and $machine.Roles.Name -notcontains 'FirstChildDC' -and $machine.Roles.Name -notcontains 'DC'))
            {
                $machinesToJoin += $machine
            }
        }
    }

    if ($machinesToJoin)
    {
        Write-Verbose -Message "Waiting for machines '$($machinesToJoin -join ', ')' to come online"
        Wait-LabVM -ComputerName $machinesToJoin -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

        Write-Verbose -Message 'Start joining the machines to the respective domains'
        Join-LabVMDomain -Machine $machinesToJoin

        Set-LabAutoLogon -ComputerName $machinesToJoin
    }
    
    Write-LogFunctionExit
}
#endregion Start-LWAzureVM

#region Stop-LWAzureVM
function Stop-LWAzureVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]
        $ComputerName,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.DefaultProgressIndicator,

        [switch]
        $NoNewLine,

        [switch]
        $ShutdownFromOperatingSystem,

        [bool]
        $StayProvisioned = $false
    )
    
    Write-LogFunctionEntry
    
    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator
    
    $lab = Get-Lab
    $azureVms = Get-AzureRmVM -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -WarningAction SilentlyContinue

    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName }
    
    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = (Get-LabVm -ComputerName $ComputerName -IncludeLinux).Where( {$_.OperatingSystemType -eq 'Linux'}, 'Split')

        $jobs += Invoke-LabCommand -ComputerName $windows -NoDisplay -AsJob -PassThru -ScriptBlock {            
            Stop-Computer -Force -ErrorAction Stop
        }
        
        $jobs += Invoke-LabCommand -UseLocalCredential -ComputerName $linux -NoDisplay -AsJob -PassThru -ScriptBlock {            
            #Sleep as background process so that job does not fail.
            [void] (Start-Job {
                    Start-Sleep -Seconds 5
                    shutdown -P now
                }) 
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object {$_.State -eq 'Failed'}
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$($failedJobs.Location)'" -Type Error
        }
    }
    else
    {
        $jobs = foreach ($name in $ComputerName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Stop-AzureRmVM -Force -StayProvisioned:$StayProvisioned -AsJob
                    
            Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
            $failedJobs = $jobs | Where-Object {$_.State -eq 'Failed'}
            if ($failedJobs)
            {
                $jobNames = ($failedJobs | ForEach-Object {
                        if ($_.Name.StartsWith("StopAzureVm_"))
                        {
                            ($_.Name -split "_")[1]
                        }
                    }) -join ", "
            
                Write-ScreenInfo -Message "Could not stop Azure VM(s): '$jobNames'" -Type Error
            }

        }
    }
    
    Write-ProgressIndicatorEnd
    
    Write-LogFunctionExit
}

#endregion Stop-LWAzureVM

#region Wait-LWAzureRestartVM
function Wait-LWAzureRestartVM
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [switch]$DoNotUseCredSsp,
        
        [double]$TimeoutInMinutes = 15,

        [int]$ProgressIndicator,

        [switch]$NoNewLine,

        [Parameter(Mandatory)]
        [datetime]
        $MonitoringStartTime
    )

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    Write-LogFunctionEntry
    
    $start = $MonitoringStartTime.ToUniversalTime()
    
    Write-Verbose -Message "Starting monitoring the servers at '$start'"
    
    $machines = Get-LabVM -ComputerName $ComputerName
        
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
            
            $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -UseLocalCredential -DoNotUseCredSsp:$DoNotUseCredSsp -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if (-not $events)
            {
                $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -DoNotUseCredSsp:$DoNotUseCredSsp -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
            
            if ($events)
            {
                Write-Verbose -Message "VM '$machine' has been restarted"
            }
            else
            {
                Start-Sleep -Seconds 10
                $machine
            }
        }
    }
    until ($machines.Count -eq 0 -or (Get-Date).ToUniversalTime().AddMinutes( - $TimeoutInMinutes) -gt $start)
    
    if (-not $NoNewLine)
    {
        Write-ProgressIndicatorEnd
    }
    
    if ((Get-Date).ToUniversalTime().AddMinutes( - $TimeoutInMinutes) -gt $start)
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
    $azureVms = Get-AzureRmVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if (-not $azureVms)
    {
        Start-Sleep -Seconds 2
        $azureVms = Get-AzureRmVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $azureVms)
        {
            throw 'Get-AzureRmVM did not return anything, stopping lab deployment. Code will be added to handle this error soon'
        }
    }

    $resourceGroups = (Get-LabVM).AzureConnectionInfo.ResourceGroupName | Select-Object -Unique
    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName -and $_.ResourceGroupName -in $resourceGroups }
    
    foreach ($azureVm in $azureVms)
    {
        if ($azureVm.PowerState -eq 'VM running')
        {
            $result.Add($azureVm.Name, 'Started')
        }
        elseif ($azureVm.PowerState -eq 'VM stopped' -or $azureVm.PowerState -eq 'VM deallocated')
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
        [AutomatedLab.Machine[]]$ComputerName
    )
    
    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue
    $retryCount = 5

    if (-not $lab)
    {
        Write-Verbose "Could not retrieve machine info for '$($ComputerName.Name -join ',')'. No lab was imported."
    }

    if (-not ((Get-AzureRmContext).Subscription.Name -eq $lab.AzureSettings.DefaultSubscription))
    {
        Set-AzureRmContext -Subscription $lab.AzureSettings.DefaultSubscription
    }

    $resourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $azureVMs = Get-AzureRmVM -WarningAction SilentlyContinue | Where-Object ResourceGroupName -in (Get-LabAzureResourceGroup).ResourceGroupName | Where-Object Name -in $ComputerName.Name

    foreach ($name in $ComputerName)
    {
        $azureVM = $azureVMs | Where-Object Name -eq $name

        if (-not $azureVM)
        { return }		

        $ip = Get-AzureRmPublicIpAddress -Name "$($resourceGroupName)$($name.Network)lbfrontendip" -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

        $result = New-Object PSObject -Property @{
            ComputerName      = $name.Name
            DnsName           = $ip.DnsSettings.Fqdn
            HttpsName         = $ip.DnsSettings.Fqdn
            VIP               = $ip.IpAddress
            Port              = $name.LoadBalancerWinrmHttpPort
            HttpsPort         = $name.LoadBalancerWinrmHttpsPort
            RdpPort           = $name.LoadBalancerRdpPort
            ResourceGroupName = $azureVM.ResourceGroupName
        }
        
        Write-Verbose "Get-LWAzureVMConnectionInfo created connection info for VM '$name'"
        Write-Verbose "ComputerName      = $($name.Name)"
        Write-Verbose "DnsName           = $($ip.DnsSettings.Fqdn)"
        Write-Verbose "HttpsName         = $($ip.DnsSettings.Fqdn)"
        Write-Verbose "VIP               = $($ip.IpAddress)"
        Write-Verbose "Port              = $($name.LoadBalancerWinrmHttpPort)"
        Write-Verbose "HttpsPort         = $($name.LoadBalancerWinrmHttpsPort)"
        Write-Verbose "RdpPort           = $($name.LoadBalancerRdpPort)"
        Write-Verbose "ResourceGroupName = $($azureVM.ResourceGroupName)"
        
        $result
    }
        
    Write-LogFunctionExit -ReturnValue $result
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
        $machines = Get-LabVM -All | Where-Object Name -in $ComputerName
    }
    else
    {
        $machines = Get-LabVM -All
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
            Invoke-LabCommand -ComputerName $machine -ActivityName SetLabVMRemoting -ScriptBlock $script -DoNotUseCredSsp -NoDisplay `
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

#region Enable-LWAzureWinRm
function Enable-LWAzureWinRm
{
    param
    (        
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]
        $Machine,

        [switch]
        $PassThru,

        [switch]
        $Wait
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    $jobs = @()

    $tempFileName = Join-Path -Path $env:TEMP -ChildPath enableazurewinrm.labtempfile.ps1
    $customScriptContent = @'
New-Item -ItemType Directory -Path C:\ALAzure -ErrorAction SilentlyContinue
'Trying to enable Remoting and CredSSP' | Out-File C:\ALAzure\WinRmActivation.log -Append
try
{
Enable-PSRemoting -Force -ErrorAction Stop
"Successfully called Enable-PSRemoting" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
"Error calling Enable-PSRemoting. $($_.Exception.Message)" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
try
{
Enable-WSManCredSSP -Role Server -Force | Out-Null
"Successfully enabled CredSSP" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
try
{
New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name auth_credssp -Value 1 -PropertyType DWORD -Force -ErrorACtion Stop
New-ItemProperty -Path HKLM:\software\Microsoft\Windows\CurrentVersion\WSMAN\Service -Name allow_remote_requests -Value 1 -PropertyType DWORD -Force -ErrorAction Stop
"Enabled CredSSP via Registry" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
catch
{
"Could not enable CredSSP via cmdlet or registry!" | Out-File C:\ALAzure\WinRmActivation.log -Append
}
}
'@
    $customScriptContent | Out-File $tempFileName -Force -Encoding utf8
    $rgName = Get-LabAzureDefaultResourceGroup

    $jobs = foreach ($m in $Machine)
    {
        Invoke-AzureRmVMRunCommand -ResourceGroupName $rgName -VMName $m.Name -ScriptPath $tempFileName -CommandId 'EnableLabRemoting' -ErrorAction Stop -AsJob
    }

    if ($Wait)
    {
        Wait-LWLabJob -Job $jobs

        $results = $jobs | Receive-Job -Keep -ErrorAction SilentlyContinue -ErrorVariable +AL_AzureWinrmActivationErrors
        $failedJobs = $jobs | Where-Object -Property Status -eq 'Failed'

        if ($failedJobs)
        {
            $machineNames = $($($failedJobs).Name -replace "'").ForEach( {$($_ -split '\s')[-1]})
            Write-ScreenInfo -Type Error -Message ('Enabling CredSSP on the following lab machines failed: {0}. Check the output of "Get-Job -Id {1} | Receive-Job -Keep" as well as the variable $AL_AzureWinrmActivationErrors' -f $($machineNames -join ','), $($failedJobs.Id -join ','))
        }
    }

    if ($PassThru)
    {
        $jobs
    }

    Remove-Item $tempFileName -Force -ErrorAction SilentlyContinue 
    Write-LogFunctionExit
}
#endregion

#region Connect-LWAzureLabSourcesDrive
function Connect-LWAzureLabSourcesDrive
{
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    
    Write-LogFunctionEntry
    
    if ($Session.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'CredSsp' -or -not (Get-LabAzureDefaultStorageAccount -ErrorAction SilentlyContinue))
    {
        return
    }

    $labSourcesStorageAccount = Get-LabAzureLabSourcesStorage
    
    $result = Invoke-Command -Session $Session -ScriptBlock {
        $pattern = '^(OK|Unavailable) +(?<DriveLetter>\w): +\\\\automatedlab'

        #remove all drive connected to an Azure LabSources share that are no longer available
        $drives = net.exe use
        $netRemoveResult = @()
        foreach ($line in $drives)
        {
            if ($line -match $pattern)
            {
                $netRemoveResult += net.exe use "$($Matches.DriveLetter):" /d
            }
        }
    
        $cmd = 'net.exe use * {0} /u:{1} {2}' -f $args[0], $args[1], $args[2]
        $cmd = [scriptblock]::Create($cmd)
        $netConnectResult = &$cmd 2>&1
        
        if (-not $LASTEXITCODE)
        {
            $ALLabSourcesMapped = $true
            Get-ChildItem -Path z:\ | Out-Null #required, otherwise sometimes accessing the UNC path did not work
        }

        New-Object PSObject -Property @{
            ReturnCode         = $LASTEXITCODE
            ALLabSourcesMapped = [bool](-not $LASTEXITCODE)
            NetConnectResult   = $netConnectResult
            NetRemoveResult    = $netRemoveResult
        }
        
    } -ArgumentList $labSourcesStorageAccount.Path, $labSourcesStorageAccount.StorageAccountName, $labSourcesStorageAccount.StorageAccountKey
    
    $Session | Add-Member -Name ALLabSourcesMappingResult -Value $result -MemberType NoteProperty
    $Session | Add-Member -Name ALLabSourcesMapped -Value $result.ALLabSourcesMapped -MemberType NoteProperty
    
    Write-LogFunctionExit
}
#endregion Connect-LWAzureLabSourcesDrive

#region Mount-LWAzureIsoImage
function Mount-LWAzureIsoImage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $IsoPath,

        [switch]$PassThru
    )
    # ISO file should already exist on Azure storage share, as it was initially retrieved from there as well.
    $azureIsoPath = $IsoPath -replace '/', '\' -replace 'https:'

    Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName.Name -join ',')" -ComputerName $ComputerName -ScriptBlock {
        $isoPath = $args[0]

        if (-not (Test-Path $isoPath))
        {
            throw "$isoPath was not accessible."
        }

        $targetPath = Join-Path -Path D: -ChildPath (Split-Path $isoPath -Leaf)
        Copy-Item -Path $isoPath -Destination $targetPath  -Force
        $drive = Mount-DiskImage -ImagePath $targetPath -StorageType ISO -PassThru | Get-Volume
        $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
        $drive | Select-Object -Property *
    } -ArgumentList $azureIsoPath -PassThru:$PassThru
}
#endregion

#region Dismount-LWAzureIsoImage
function Dismount-LWAzureIsoImage
{
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $ComputerName
    )

    Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Dismounting ISO Images on Azure machines $($ComputerName -join ',')" -ScriptBlock {
        
        $originalImage = Get-ChildItem -Path D:\ -Filter *.iso | Foreach-Object { Get-DiskImage -ImagePath $_.FullName } | Where-Object Attached

        if ($originalImage)
        {
            Write-Verbose -Message "Dismounting $($originalImage.ImagePath -join ',')"
            $originalImage | Dismount-DiskImage

            Write-Verbose -Message "Removing temporary file $($originalImage.ImagePath -join ',')"
            Remove-Item -Path $originalImage.ImagePath -Force
        }
    }
}
#endregion