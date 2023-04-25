function New-LWAzureVM
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

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

    if (Get-AzVM -Name $machine.ResourceName -ResourceGroupName $machineResourceGroup -ErrorAction SilentlyContinue)
    {
        Write-PSFMessage -Message "Target machine $($machine.ResourceName) already exists. Skipping..."
        return
    }

    Write-PSFMessage -Message "Target resource group for machine: '$machineResourceGroup'"

    if (-not $global:cacheVMs)
    {
        $global:cacheVMs = Get-AzVM
    }

    if ($global:cacheVMs | Where-Object { $_.Name -eq $Machine.ResourceName -and $_.ResourceGroupName -eq $resourceGroupName })
    {
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message "Machine '$($machine.ResourceName)' already exist. Skipping creation of this machine" -Type Warning
        return
    }

    Write-PSFMessage -Message "Scheduling creation Azure machine '$Machine'"

    #random number in the path to prevent conflicts
    $rnd = (Get-Random -Minimum 1 -Maximum 1000).ToString('0000')

    $adminUserName = $Machine.InstallationUser.UserName
    $adminPassword = $Machine.InstallationUser.Password

    $skuOffer = Get-LWAzureSku -Machine $Machine
    $offerName = $skuOffer.offer
    $publisherName = $skuOffer.publisher
    $skusName = $skuOffer.sku

    Write-ProgressIndicator

    $roleSize = Get-LWAzureVmSize -Machine $Machine

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
    $LabName = $lab.Name

    Write-PSFMessage '-------------------------------------------------------'
    Write-PSFMessage "Machine: $($machine.ResourceName)"
    Write-PSFMessage "Vnet: $Vnet"
    Write-PSFMessage "RoleSize: $RoleSize"
    Write-PSFMessage "VmImageName: $VmImageName"
    Write-PSFMessage "AdminUserName: $AdminUserName"
    Write-PSFMessage "AdminPassword: $AdminPassword"
    Write-PSFMessage "ResourceGroupName: $ResourceGroupName"
    Write-PSFMessage "DefaultIpAddress: $DefaultIpAddress"
    Write-PSFMessage "Location: $Location"
    Write-PSFMessage "Lab name: $LabName"
    Write-PSFMessage "Publisher: $PublisherName"
    Write-PSFMessage "Offer: $OfferName"
    Write-PSFMessage "Skus: $SkusName"
    Write-PSFMessage '-------------------------------------------------------'

    $subnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName |
    Get-AzVirtualNetworkSubnetConfig |
    Where-Object -FilterScript {
                (Get-NetworkRange -IPAddress $_.AddressPrefix) -contains $machine.IpAddress[0].IpAddress.ToString()
    }

    if (-not $subnet)
    {
        throw 'No subnet configuration found to fit machine in! Review the IP address of your machine and your lab virtual network.'
    }

    Write-PSFMessage -Message "Subnet for the VM is '$($subnet.Name)'"
    $cred = New-Object -TypeName pscredential -ArgumentList $adminUserName, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

    $machineAvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -ErrorAction SilentlyContinue
    if (-not ($machineAvailabilitySet))
    {
        $machineAvailabilitySet = New-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -Location $Location -ErrorAction Stop -Sku aligned -PlatformUpdateDomainCount 2 -PlatformFaultDomainCount 2
    }

    $useULTRA = $false
    if ($Machine.AzureProperties.ContainsKey('StorageSku'))
    {
        $useULTRA = $Machine.AzureProperties['StorageSku'] -eq 'UltraSSD_LRS'
    }

    $vm = New-AzVMConfig -VMName $Machine.ResourceName -VMSize $RoleSize -AvailabilitySetId $machineAvailabilitySet.Id  -ErrorAction Stop -EnableUltraSSD:$useULTRA
    $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $Machine.ResourceName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -ErrorAction Stop -WinRMHttp

    Write-PSFMessage "Choosing latest source image for $SkusName in $OfferName"
    $vm = Set-AzVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $OfferName -Skus $SkusName -Version "latest" -ErrorAction Stop

    Write-PSFMessage -Message "Setting private IP address."
    $defaultIPv4Address = $DefaultIpAddress

    Write-PSFMessage -Message "Default IP address is '$DefaultIpAddress'."

    Write-PSFMessage -Message 'Locating load balancer and assigning NIC to appropriate rules and pool'
    $LoadBalancer = Get-AzLoadBalancer -Name "$($ResourceGroupName)$($machine.Network[0])loadbalancer" -ResourceGroupName $resourceGroupName -ErrorAction Stop

    $inboundNatRules = @(Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.ResourceName.ToLower())rdpin" -ErrorAction SilentlyContinue)
    $inboundNatRules += Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.ResourceName.ToLower())winrmin" -ErrorAction SilentlyContinue
    $inboundNatRules += Get-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $LoadBalancer -Name "$($machine.ResourceName.ToLower())winrmhttpsin" -ErrorAction SilentlyContinue

    $nicProperties = @{
        Name                           = "$($machine.ResourceName.ToLower())nic0"
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

    Write-PSFMessage -Message "Creating new network interface with configured private and public IP and subnet $($subnet.Name)"
    $networkInterface = New-AzNetworkInterface @nicProperties

    Write-PSFMessage -Message 'Adding primary NIC to VM'
    $vm = Add-AzVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop -Primary

    Write-ProgressIndicator

    if ($Disks)
    {
        $diskSku = if ($Machine.AzureProperties.ContainsKey('StorageSku'))
        {
            $Machine.AzureProperties['StorageSku']
        }
        else
        {
            'Premium_LRS'
        }
        Write-PSFMessage "Adding $($Disks.Count) data disks"
        $lun = 0

        foreach ($Disk in $Disks.GetEnumerator())
        {
            $dataDiskName = $Disk.Key.ToLower()
            $diskSize = $Disk.Value

            Write-PSFMessage -Message "Adding disk $dataDiskName to VM $Machine with $diskSize GB (LUN $lun)"
            $diskConfig = New-AzDiskConfig -SkuName $diskSku -DiskSizeGB $diskSize -CreateOption Empty -Location $Location
            $dataDisk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $dataDiskName -Disk $diskConfig
            $vm = $vm | Add-AzVMDataDisk -Name $dataDiskName -ManagedDiskId $dataDisk.Id -Caching None -DiskSizeInGB $diskSize -Lun $lun -CreateOption Attach
            $lun++
        }
    }

    Write-ProgressIndicator

    #Add any additional NICs to the VM configuration
    $niccount = 1
    foreach ($adapter in ($Machine.NetworkAdapters | Where-Object { $_.Ipv4Address.IPAddress.ToString() -ne $defaultIPv4Address }))
    {
        $subnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName |
        Get-AzVirtualNetworkSubnetConfig |
        Where-Object -FilterScript {
                (Get-NetworkRange -IPAddress $_.AddressPrefix) -contains $adapter.Ipv4Address[0].IpAddress.ToString()
        }

        Write-PSFMessage -Message "Adding additional network adapter to $Machine"
        $additionalNicParameters = @{
            Name              = "$($machine.ResourceName.ToLower())nic$niccount"
            ResourceGroupName = $ResourceGroupName
            Location          = $Location
            Subnet            = $subnet
            PrivateIpAddress  = ($adapter.Ipv4Address.IpAddress.AddressAsString)
            Force             = $true
        }

        $networkInterface = New-AzNetworkInterface @additionalNicParameters
        $vm = Add-AzVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop
        $niccount++
    }

    Write-PSFMessage -Message 'Calling New-AzureRMVm'

    $vmParameters = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
        VM                = $vm
        Tag               = @{ AutomatedLab = $LabName; CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
        ErrorAction       = 'Stop'
        WarningAction     = 'SilentlyContinue'
        AsJob             = $true
    }

    New-AzVM @vmParameters
    Write-LogFunctionExit
}
