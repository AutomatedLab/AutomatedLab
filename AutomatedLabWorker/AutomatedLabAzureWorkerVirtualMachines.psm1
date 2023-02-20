function New-LabAzureResourceGroupDeployment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Lab]
        $Lab,

        [Parameter()]
        [switch]
        $PassThru,

        [Parameter()]
        [switch]
        $Wait
    )

    Write-LogFunctionEntry

    $template = @{
        '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        contentVersion = '1.0.0.0'  
        parameters     = @{ }
        resources      = @()
    }

    # The handy providers() function was deprecated and the latest provider APIs started getting error-prone and unpredictable
    # The following list was generated on Jul 12 2022
    $apiVersions = if (Get-LabConfigurationItem -Name UseLatestAzureProviderApi)
    {
        $providers = Get-AzResourceProvider -Location $lab.AzureSettings.DefaultLocation.Location -ErrorAction SilentlyContinue | Where-Object RegistrationState -eq 'Registered'
        $provHash = @{
            NicApi             = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'networkInterfaces').ApiVersions[0] # 2022-01-01
            DiskApi            = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'disks').ApiVersions[0] # 2022-01-01
            LoadBalancerApi    = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'loadBalancers').ApiVersions[0] # 2022-01-01
            PublicIpApi        = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'publicIpAddresses').ApiVersions[0] # 2022-01-01
            VirtualNetworkApi  = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualNetworks').ApiVersions[0] # 2022-01-01
            NsgApi             = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'networkSecurityGroups').ApiVersions[0] # 2022-01-01
            AvailabilitySetApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'availabilitySets').ApiVersions[1] # 2022-03-01
            VmApi              = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualMachines').ApiVersions[1] # 2022-03-01
        }
        if (-not $lab.AzureSettings.IsAzureStack)
        {
            $provHash.BastionHostApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'bastionHosts').ApiVersions[0] # 2022-01-01
        }
        if ($lab.AzureSettings.IsAzureStack)
        {
            $provHash.AvailabilitySetApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'availabilitySets').ApiVersions[0]
            $provHash.VmApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualMachines').ApiVersions[0]
        }
        $provHash
    }
    elseif ($Lab.AzureSettings.IsAzureStack)
    {
        @{
            NicApi             = '2018-11-01'
            DiskApi            = '2018-11-01'
            AvailabilitySetApi = '2020-06-01'
            LoadBalancerApi    = '2018-11-01'
            PublicIpApi        = '2018-11-01'
            VirtualNetworkApi  = '2018-11-01'
            NsgApi             = '2018-11-01'
            VmApi              = '2020-06-01'
        }
    }
    else
    {
        @{
            NicApi             = '2022-01-01'
            DiskApi            = '2022-01-01'
            AvailabilitySetApi = '2022-03-01'
            LoadBalancerApi    = '2022-01-01'
            PublicIpApi        = '2022-01-01'
            VirtualNetworkApi  = '2022-01-01'
            BastionHostApi     = '2022-01-01'
            NsgApi             = '2022-01-01'
            VmApi              = '2022-03-01'
        }
    }
    
    #region Network Security Group
    Write-ScreenInfo -Type Verbose -Message 'Adding network security group to template, enabling traffic to ports 3389,5985,5986,22 for VMs behind load balancer'
    [string[]]$allowedIps = (Get-LabVm).AzureProperties["LoadBalancerAllowedIp"] | Foreach-Object { $_ -split '\s*[,;]\s*' } | Where-Object { -not [string]::IsNullOrWhitespace($_) }
    $nsg = @{
        type       = "Microsoft.Network/networkSecurityGroups"
        apiVersion = $apiVersions['NsgApi']
        name       = "nsg"
        location   = "[resourceGroup().location]"
        tags       = @{ 
            AutomatedLab = $Lab.Name
            CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        properties = @{
            securityRules = @(
                # Necessary mgmt ports for AutomatedLab
                @{
                    name       = "NecessaryPorts"
                    properties = @{
                        protocol                   = "TCP"
                        sourcePortRange            = "*"
                        sourceAddressPrefix        = if ($allowedIps) { $null } else { "*" }
                        destinationAddressPrefix   = "VirtualNetwork"
                        access                     = "Allow"
                        priority                   = 100
                        direction                  = "Inbound"
                        sourcePortRanges           = @()
                        destinationPortRanges      = @(
                            "22"
                            "3389"
                            "5985"
                            "5986"
                        )
                        sourceAddressPrefixes      = @()
                        destinationAddressPrefixes = @()
                    }
                }
                # Rules for bastion host deployment - always included to be able to deploy bastion at a later stage
                @{
                    name       = "BastionIn"
                    properties = @{
                        protocol                   = "TCP"
                        sourcePortRange            = "*"
                        sourceAddressPrefix        = if ($allowedIps) { $null } else { "*" }
                        destinationAddressPrefix   = "*"
                        access                     = "Allow"
                        priority                   = 101
                        direction                  = "Inbound"
                        sourcePortRanges           = @()
                        destinationPortRanges      = @(
                            "443"
                        )
                        sourceAddressPrefixes      = @()
                        destinationAddressPrefixes = @()
                    }
                }
                if (-not $Lab.AzureSettings.IsAzureStack)
                {
                    @{
                        name       = "BastionMgmtOut"
                        properties = @{
                            protocol                   = "TCP"
                            sourcePortRange            = "*"
                            sourceAddressPrefix        = "*"
                            destinationAddressPrefix   = "AzureCloud"
                            access                     = "Allow"
                            priority                   = 100
                            direction                  = "Outbound"
                            sourcePortRanges           = @()
                            destinationPortRanges      = @(
                                "443"
                            )
                            sourceAddressPrefixes      = @()
                            destinationAddressPrefixes = @()
                        }
                    }
                    @{
                        name       = "BastionRdsOut"
                        properties = @{
                            protocol                   = "TCP"
                            sourcePortRange            = "*"
                            sourceAddressPrefix        = "*"
                            destinationAddressPrefix   = "VirtualNetwork"
                            access                     = "Allow"
                            priority                   = 101
                            direction                  = "Outbound"
                            sourcePortRanges           = @()
                            destinationPortRanges      = @(
                                "3389"
                                "22"
                            )
                            sourceAddressPrefixes      = @()
                            destinationAddressPrefixes = @()
                        }
                    }
                }
            )
        }
    }

    if ($allowedIps)
    {
        $nsg.properties.securityrules | Where-Object { $_.properties.direction -eq 'Inbound' } | Foreach-object { $_.properties.sourceAddressPrefixes = $allowedIps }
    }
    $template.resources += $nsg
    #endregion

    #region Wait for availability of Bastion
    if ($Lab.AzureSettings.AllowBastionHost -and -not $lab.AzureSettings.IsAzureStack)
    {
        $bastionFeature = Get-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
        while (($bastionFeature).RegistrationState -ne 'Registered')
        {
            if ($bastionFeature.RegistrationState -eq 'NotRegistered')
            {
                $null = Register-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
                $null = Register-AzProviderFeature -FeatureName bastionShareableLink -ProviderNamespace Microsoft.Network
            }

            Start-Sleep -Seconds 5
            Write-ScreenInfo -Type Verbose -Message "Waiting for registration of bastion host feature. Current status: $(($bastionFeature).RegistrationState)"
            $bastionFeature = Get-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
        }
    }

    $vnetCount = 0
    $loadbalancers = @{}
    foreach ($network in $Lab.VirtualNetworks)
    {
        #region VNet
        Write-ScreenInfo -Type Verbose -Message ('Adding vnet {0} ({1}) to template' -f $network.ResourceName, $network.AddressSpace)
        $vNet = @{
            type       = "Microsoft.Network/virtualNetworks"
            apiVersion = $apiVersions['VirtualNetworkApi']
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            dependsOn  = @(
                "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg')]"
            )
            name       = $network.ResourceName
            location   = "[resourceGroup().location]"
            properties = @{
                addressSpace = @{
                    addressPrefixes = @(
                        $network.AddressSpace.ToString()
                    )
                }
                subnets      = @()
                dhcpOptions  = @{
                    dnsServers = @()
                }
            }
        }

        if ($network.DnsServers -and -not $lab.AzureSettings.IsAzureStack)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding DNS Servers to VNet template: {0}' -f $network.DnsServers)
            $vNet.properties.dhcpOptions.dnsServers = [string[]]($network.DnsServers.AddressAsString)
        }

        if (-not $network.Subnets)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding default subnet ({0}) to VNet' -f $network.AddressSpace)
            $vnet.properties.subnets += @{
                name       = "default"
                properties = @{
                    addressPrefix        = $network.AddressSpace.ToString()
                    networkSecurityGroup = @{
                        id = "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg')]"
                    }
                }
            }
        }

        foreach ($subnet in $network.Subnets)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding subnet {0} ({1}) to VNet' -f $subnet.Name, $subnet.AddressSpace)
            $vnet.properties.subnets += @{
                name       = $subnet.Name
                properties = @{
                    addressPrefix        = $subnet.AddressSpace.ToString()
                    networkSecurityGroup = @{
                        id = "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg')]"
                    }
                }
            }
        }

        if ($Lab.AzureSettings.AllowBastionHost -and -not $lab.AzureSettings.IsAzureStack)
        {
            if ($network.Subnets.Name -notcontains 'AzureBastionSubnet')
            {
                $sourceMask = $network.AddressSpace.Cidr
                $sourceMaskIp = $network.AddressSpace.NetMask
                $sourceRange = Get-NetworkRange -IPAddress $network.AddressSpace.IpAddress.AddressAsString -SubnetMask $network.AddressSpace.NetMask
                $sourceInfo = Get-NetworkSummary -IPAddress $network.AddressSpace.IpAddress.AddressAsString -SubnetMask $network.AddressSpace.NetMask
                $superNetMask = $sourceMask - 1
                $superNetIp = $network.AddressSpace.IpAddress.AddressAsString
                $superNet = [AutomatedLab.VirtualNetwork]::new()
                $superNet.AddressSpace = '{0}/{1}' -f $superNetIp, $superNetMask
                $superNetInfo = Get-NetworkSummary -IPAddress $superNet.AddressSpace.IpAddress.AddressAsString -SubnetMask $superNet.AddressSpace.NetMask

                foreach ($address in (Get-NetworkRange -IPAddress $superNet.AddressSpace.IpAddress.AddressAsString -SubnetMask $superNet.AddressSpace.NetMask))
                {
                    if ($address -in @($sourceRange + $sourceInfo.Network + $sourceInfo.Broadcast))
                    {
                        continue
                    }

                    $bastionNet = [AutomatedLab.VirtualNetwork]::new()
                    $bastionNet.AddressSpace = '{0}/{1}' -f $address, $sourceMask
                    break
                }

                $vNet.properties.addressSpace.addressPrefixes = @(
                    $superNet.AddressSpace.ToString()
                )
                $vnet.properties.subnets += @{
                    name       = 'AzureBastionSubnet'
                    properties = @{
                        addressPrefix        = $bastionNet.AddressSpace.ToString()
                        networkSecurityGroup = @{
                            id = "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg')]"
                        }
                    }
                }
            }

            $dnsLabel = "[concat('azbastion', uniqueString(resourceGroup().id))]"
            Write-ScreenInfo -Type Verbose -Message ('Adding Azure bastion public static IP with DNS label {0} to template' -f $dnsLabel)
            $template.resources +=
            @{
                apiVersion = $apiVersions['PublicIpApi']
                tags       = @{ 
                    AutomatedLab = $Lab.Name
                    CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
                type       = "Microsoft.Network/publicIPAddresses"
                name       = "$($vnetCount)bip"
                location   = "[resourceGroup().location]"
                properties = @{
                    publicIPAllocationMethod = "static"
                    dnsSettings              = @{
                        domainNameLabel = $dnsLabel
                    }
                }
                sku        = @{
                    name = if ($Lab.AzureSettings.IsAzureStack) { 'Basic' } else { 'Standard' }
                }
            }

            $template.resources += @{
                apiVersion = $apiVersions['BastionHostApi']
                type       = "Microsoft.Network/bastionHosts"
                name       = "bastion$vnetCount"
                tags       = @{ 
                    AutomatedLab = $Lab.Name
                    CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
                location   = "[resourceGroup().location]"
                dependsOn  = @(
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($network.ResourceName)')]"
                    "[resourceId('Microsoft.Network/publicIPAddresses', '$($vnetCount)bip')]"
                )
                properties = @{
                    ipConfigurations = @(
                        @{
                            name       = "IpConf"
                            properties = @{
                                subnet          = @{
                                    id = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '$($network.ResourceName)','AzureBastionSubnet')]"
                                }
                                publicIPAddress = @{
                                    id = "[resourceId('Microsoft.Network/publicIPAddresses', '$($vnetCount)bip')]"
                                }
                            }
                        }
                    )
                }
            }
        }

        $template.resources += $vNet
        #endregion

        #region Peering
        foreach ($peer in $network.ConnectToVnets)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding peering from {0} to {1} to VNet template' -f $network.ResourceName, $peer)
            $template.Resources += @{
                apiVersion = $apiVersions['VirtualNetworkApi']
                dependsOn  = @(
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($network.ResourceName)')]"
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($peer)')]"
                )
                type       = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings"
                name       = "$($network.ResourceName)/$($network.ResourceName)To$($peer)"
                location   = "[resourceGroup().location]"
                properties = @{
                    allowVirtualNetworkAccess = $true
                    allowForwardedTraffic     = $false
                    allowGatewayTransit       = $false
                    useRemoteGateways         = $false
                    remoteVirtualNetwork      = @{
                        id = "[resourceId('Microsoft.Network/virtualNetworks', '$peer')]"
                    }
                }
            }
        }
        #endregion

        #region Public Ip
        $dnsLabel = "[concat('al$vnetCount-', uniqueString(resourceGroup().id))]"

        if ($network.AzureDnsLabel)
        {
            $dnsLabel = $network.AzureDnsLabel
        }

        Write-ScreenInfo -Type Verbose -Message ('Adding public static IP with DNS label {0} to template' -f $dnsLabel)
        $template.resources +=
        @{
            apiVersion = $apiVersions['PublicIpApi']
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                Vnet         = $network.ResourceName
            }
            type       = "Microsoft.Network/publicIPAddresses"
            name       = "lbip$vnetCount"
            location   = "[resourceGroup().location]"
            properties = @{
                publicIPAllocationMethod = "static"
                dnsSettings              = @{
                    domainNameLabel = $dnsLabel
                }
            }
            sku        = @{
                name = if ($Lab.AzureSettings.IsAzureStack) { 'Basic' } else { 'Standard' }
            }
        }
        #endregion

        #region Load balancer
        Write-ScreenInfo -Type Verbose -Message ('Adding load balancer to template')
        $loadbalancers[$network.ResourceName] = @{
            Name    = "lb$vnetCount"
            Backend = "$($vnetCount)lbbc"
        }
        $loadBalancer = @{
            type       = "Microsoft.Network/loadBalancers"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                Vnet         = $network.ResourceName
            }
            apiVersion = $apiVersions['LoadBalancerApi']
            name       = "lb$vnetCount"
            location   = "[resourceGroup().location]"
            sku        = @{
                name = if ($Lab.AzureSettings.IsAzureStack) { 'Basic' } else { 'Standard' }
            }
            dependsOn  = @(
                "[resourceId('Microsoft.Network/publicIPAddresses', 'lbip$vnetCount')]"
            )
            properties = @{
                frontendIPConfigurations = @(
                    @{
                        name       = "$($vnetCount)lbfc"
                        properties = @{
                            publicIPAddress = @{
                                id = "[resourceId('Microsoft.Network/publicIPAddresses', 'lbip$vnetCount')]"
                            }
                        }
                    }
                )
                backendAddressPools      = @(
                    @{
                        name = "$($vnetCount)lbbc"
                    }
                )
            }
        }

        if (-not $Lab.AzureSettings.IsAzureStack)
        {
            $loadbalancer.properties.outboundRules = @(
                @{
                    name       = "InternetAccess"
                    properties = @{
                        allocatedOutboundPorts   = 0 # In order to use automatic allocation
                        frontendIPConfigurations = @(
                            @{
                                id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb$vnetCount', '$($vnetCount)lbfc')]"
                            }
                        )
                        backendAddressPool       = @{
                            id = "[concat(resourceId('Microsoft.Network/loadBalancers', 'lb$vnetCount'), '/backendAddressPools/$($vnetCount)lbbc')]"
                        }
                        protocol                 = "All"
                        enableTcpReset           = $true
                        idleTimeoutInMinutes     = 4
                    }
                }
            )
        }

        $rules = foreach ($machine in ($Lab.Machines | Where-Object -FilterScript { $_.Network -EQ $network.Name -and -not $_.SkipDeployment }))
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding inbound NAT rules for {0}: {1}:3389, {2}:5985, {3}:5986, {4}:22' -f $machine, $machine.LoadBalancerRdpPort, $machine.LoadBalancerWinRmHttpPort, $machine.LoadBalancerWinrmHttpsPort, $machine.LoadBalancerSshPort)
            @{
                name       = "$($machine.ResourceName.ToLower())rdpin"
                properties = @{
                    frontendIPConfiguration = @{
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb$vnetCount', '$($vnetCount)lbfc')]"
                    }
                    frontendPort            = $machine.LoadBalancerRdpPort
                    backendPort             = 3389
                    enableFloatingIP        = $false
                    protocol                = "Tcp"
                }
            }
            @{
                name       = "$($machine.ResourceName.ToLower())winrmin"
                properties = @{
                    frontendIPConfiguration = @{
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb$vnetCount', '$($vnetCount)lbfc')]"
                    }
                    frontendPort            = $machine.LoadBalancerWinRmHttpPort
                    backendPort             = 5985
                    enableFloatingIP        = $false
                    protocol                = "Tcp"
                }
            }
            @{
                name       = "$($machine.ResourceName.ToLower())winrmhttpsin"
                properties = @{
                    frontendIPConfiguration = @{
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb$vnetCount', '$($vnetCount)lbfc')]"
                    }
                    frontendPort            = $machine.LoadBalancerWinrmHttpsPort
                    backendPort             = 5986
                    enableFloatingIP        = $false
                    protocol                = "Tcp"
                }
            }
            @{
                name       = "$($machine.ResourceName.ToLower())sshin"
                properties = @{
                    frontendIPConfiguration = @{
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb$vnetCount', '$($vnetCount)lbfc')]"
                    }
                    frontendPort            = $machine.LoadBalancerSshPort
                    backendPort             = 22
                    enableFloatingIP        = $false
                    protocol                = "Tcp"
                }
            }
        }

        $loadBalancer.properties.inboundNatRules = $rules
        $template.resources += $loadBalancer
        #endregion

        #region AvailabilitySet
        Write-ScreenInfo -Type Verbose -Message ('Adding availability set to template')
        $template.resources += @{
            type       = "Microsoft.Compute/availabilitySets"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            apiVersion = $apiVersions['AvailabilitySetApi']
            name       = "$($network.ResourceName)"
            location   = "[resourceGroup().location]"
            sku        = @{
                name = "Aligned"
            }
            properties = @{
                platformUpdateDomainCount = 2
                platformFaultDomainCount  = 2
            }
        }
        #endregion
        $vnetCount++
    }

    #region Disks
    foreach ($disk in $Lab.Disks)
    {
        if (-not $disk) { continue } # Due to an issue with the disk collection being enumerated even if it is empty
        Write-ScreenInfo -Type Verbose -Message ('Creating managed data disk {0} ({1} GB)' -f $disk.Name, $disk.DiskSize)
        $vm = $lab.Machines | Where-Object { $_.Disks.Name -contains $disk.Name }
        $template.resources += @{
            type       = "Microsoft.Compute/disks"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            apiVersion = $apiVersions['DiskApi']
            name       = $disk.Name
            location   = "[resourceGroup().location]"
            sku        = @{
                name = if ($vm.AzureProperties.StorageSku)
                {
                    $vm.AzureProperties['StorageSku']
                }
                else
                {
                    "Standard_LRS"
                }
            }
            properties = @{
                creationData = @{
                    createOption = "Empty"
                }
                diskSizeGB   = $disk.DiskSize
            }
        }
    }
    #endregion

    foreach ($machine in $Lab.Machines.Where({ -not $_.SkipDeployment }))
    {
        $niccount = 0
        foreach ($nic in $machine.NetworkAdapters)
        {
            Write-ScreenInfo -Type Verbose -Message ('Creating NIC {0}' -f $nic.InterfaceName)
            $subnetName = 'default'

            foreach ($subnetConfig in $nic.VirtualSwitch.Subnets)
            {
                if ($subnetConfig.Name -eq 'AzureBastionSubnet') { continue }

                $usable = Get-NetworkRange -IPAddress $subnetConfig.AddressSpace.IpAddress.AddressAsString -SubnetMask $subnetConfig.AddressSpace.Cidr
                if ($nic.Ipv4Address[0].IpAddress.AddressAsString -in $usable)
                {
                    $subnetName = $subnetConfig.Name
                }
            }

            $machineInboundRules = @(
                @{
                    id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)'),'/inboundNatRules/$($machine.ResourceName.ToLower())rdpin')]"
                }
                @{
                    id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)'),'/inboundNatRules/$($machine.ResourceName.ToLower())winrmin')]"
                }
                @{
                    id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)'),'/inboundNatRules/$($machine.ResourceName.ToLower())winrmhttpsin')]"
                }
                @{
                    id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)'),'/inboundNatRules/$($machine.ResourceName.ToLower())sshin')]"
                }
            )
             
            $nicTemplate = @{
                dependsOn  = @(
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($nic.VirtualSwitch.ResourceName)')]"
                    "[resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)')]"
                )
                properties = @{
                    enableAcceleratedNetworking = $false
                    ipConfigurations            = @(
                        @{
                            properties = @{
                                subnet                    = @{
                                    id = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '$($nic.VirtualSwitch.ResourceName)', '$subnetName')]"
                                }
                                primary                   = $true
                                privateIPAllocationMethod = "Static"
                                privateIPAddress          = $nic.Ipv4Address[0].IpAddress.AddressAsString
                                privateIPAddressVersion   = "IPv4"
                            }
                            name       = "ipconfig1"
                        }
                    )
                    enableIPForwarding          = $false
                }
                name       = "$($machine.ResourceName)nic$($niccount)"
                apiVersion = $apiVersions['NicApi']
                type       = "Microsoft.Network/networkInterfaces"
                location   = "[resourceGroup().location]"
                tags       = @{ 
                    AutomatedLab = $Lab.Name
                    CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
            }

            # Add NAT only to first nic
            if ($niccount -eq 0)
            {
                $nicTemplate.properties.ipConfigurations[0].properties.loadBalancerInboundNatRules = $machineInboundRules
                $nicTemplate.properties.ipConfigurations[0].properties.loadBalancerBackendAddressPools = @(
                    @{
                        id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($loadBalancers[$nic.VirtualSwitch.ResourceName].Name)'), '/backendAddressPools/$($loadBalancers[$nic.VirtualSwitch.ResourceName].Backend)')]"
                    }
                )
            }

            if ($nic.Ipv4DnsServers)
            {
                $nicTemplate.properties.dnsSettings = @{
                    dnsServers = [string[]]($nic.Ipv4DnsServers.AddressAsString)
                }
            }
            $template.resources += $nicTemplate
            $niccount++
        }

        Write-ScreenInfo -Type Verbose -Message ('Adding machine template')
        $vmSize = Get-LWAzureVmSize -Machine $Machine
        $imageRef = Get-LWAzureSku -Machine $machine

        if ($vmSize.Gen2Supported -and -not $vmSize.Gen1Supported)
        {
            $pattern = '{0}(-g2$|gen2|-gensecond$)' -f $imageRef.sku # Yes, why should the image names be consistent? Also of course we don't need a damn VMGeneration property...
            $newImage = $lab.AzureSettings.VMImages | Where-Object { $_.PublisherName -eq $imageref.Publisher -and $_.Offer -eq $imageref.Offer -and $_.Skus -match $pattern }
            if (-not $newImage)
            {
                throw "Selected VM size $vmSize for $Machine only suppports G2 VMs, however no matching Generation 2 image was found for your selection: Publisher $($imageRef.publisher), offer $($imageRef.offer), sku $($imageRef.sku)!"
            }

            $imageRef = @{
                publisher = $newImage.PublisherName
                version   = $newImage.Version
                offer     = $newImage.Offer
                sku       = $newImage.Skus
            }
        }

        if (-not $vmSize)
        {
            throw "No valid VM size found for $Machine!"
        }

        Write-ScreenInfo -Type Verbose -Message "Adding $Machine with size $vmSize, publisher $($imageRef.publisher), offer $($imageRef.offer), sku $($imageRef.sku)!"

        $machNet = Get-LabVirtualNetworkDefinition -Name $machine.Network[0]
        $machTemplate = @{
            name       = $machine.ResourceName
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            dependsOn  = @(
                "[resourceId('Microsoft.Compute/availabilitySets', '$($machNet.ResourceName)')]"
            )
            properties = @{
                availabilitySet = @{
                    id = "[resourceId('Microsoft.Compute/availabilitySets', '$($machNet.ResourceName)')]"
                }
                storageProfile  = @{
                    osDisk         = @{
                        createOption = "FromImage"
                        osType       = "Windows"
                        caching      = "ReadWrite"
                        managedDisk  = @{
                            storageAccountType = if ($Machine.AzureProperties.ContainsKey('StorageSku') -and $Machine.AzureProperties['StorageSku'] -notmatch 'ultra')
                            {
                                $Machine.AzureProperties['StorageSku']
                            }
                            elseif ($Machine.AzureProperties.ContainsKey('StorageSku') -and $Machine.AzureProperties['StorageSku'] -match 'ultra')
                            {
                                Write-ScreenInfo -Type Warning -Message "Ultra_SSD SKU selected, defaulting to Premium_LRS for OS disk."
                                'Premium_LRS'
                            }
                            else
                            {
                                'Standard_LRS'
                            }
                        }
                    }                    
                    imageReference = $imageRef
                    dataDisks      = @()
                }
                networkProfile  = @{
                    networkInterfaces = @()
                }
                osProfile       = @{
                    adminPassword            = $machine.GetLocalCredential($true).GetNetworkCredential().Password
                    computerName             = $machine.Name
                    allowExtensionOperations = $true
                    adminUsername            = ($machine.GetLocalCredential($true).UserName -split '\\')[-1]
                    windowsConfiguration     = @{
                        enableAutomaticUpdates = $true
                        provisionVMAgent       = $true
                        winRM                  = @{
                            listeners = @(
                                @{
                                    protocol = "Http"
                                }
                            )
                        }
                    }
                }
                hardwareProfile = @{
                    vmSize = $vmSize.Name
                }
            }
            type       = "Microsoft.Compute/virtualMachines"
            apiVersion = $apiVersions['VmApi']
            location   = "[resourceGroup().location]"
        }
        
        if ($machine.AzureProperties['EnableSecureBoot'] -and -not $lab.AzureSettings.IsAzureStack) # Available only in public regions
        {            
            $machTemplate.properties.securityProfile = @{
                securityType     = 'TrustedLaunch'
                uefiSettings     = @{
                    secureBootEnabled = $true
                    vTpmEnabled       = $Machine.AzureProperties['EnableTpm'] -match '1|true|yes'
                }
            }
        }

        $luncount = 0
        foreach ($disk in $machine.Disks)
        {
            if (-not $disk) { continue } # Due to an issue with the disk collection being enumerated even if it is empty
            Write-ScreenInfo -Type Verbose -Message ('Adding disk {0} to machine template' -f $disk.Name)
            $machTemplate.properties.storageProfile.dataDisks += @{
                lun          = $luncount
                name         = $disk.Name
                createOption = "attach"
                managedDisk  = @{
                    id = "[resourceId('Microsoft.Compute/disks/', '$($disk.Name)')]"
                }
            }
            $luncount++
        }

        $niccount = 0
        foreach ($nic in $machine.NetworkAdapters)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding NIC {0} to template' -f $nic.InterfaceName)
            $machtemplate.dependsOn += "[resourceId('Microsoft.Network/networkInterfaces', '$($machine.ResourceName)nic$($niccount)')]"
            $machTemplate.properties.networkProfile.networkInterfaces += @{
                id         = "[resourceId('Microsoft.Network/networkInterfaces', '$($machine.ResourceName)nic$($niccount)')]"
                properties = @{
                    primary = $niccount -eq 0
                }
            }
            $niccount++
        }
        
        $template.resources += $machTemplate
    }

    $rgDeplParam = @{
        TemplateObject    = $template
        ResourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
        Force             = $true
    }

    $templatePath = Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath "Labs/$($Lab.Name)/armtemplate.json"
    $template | ConvertTo-JsonNewtonsoft | Set-Content -Path $templatePath

    Write-ScreenInfo -Message "Deploying new resource group with template $templatePath"
    # Without wait - unable to catch exception
    if ($Wait.IsPresent)
    {
        $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
        $count = 1
        while ($count -le $azureRetryCount -and -not $deployment)
        {
            try
            {
                $deployment = New-AzResourceGroupDeployment @rgDeplParam -ErrorAction Stop
            }
            catch
            {
                if ($_.Exception.Message -match 'Code:NoRegisteredProviderFound')
                {
                    $count++
                }
                else
                {
                    Write-Error -Message 'Unrecoverable error during resource group deployment' -Exception $_.Exception
                    return
                }
            }
        }
        if ($count -gt $azureRetryCount)
        {
            Write-Error -Message 'Unrecoverable error during resource group deployment'
            return
        }
    }
    else
    {
        $deployment = New-AzResourceGroupDeployment @rgDeplParam -AsJob # Splatting AsJob did not work
    }
    

    if ($PassThru.IsPresent)
    {
        $deployment
    }

    Write-LogFunctionExit
}
function Get-LWAzureVmSize
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $lab = Get-Lab

    if ($machine.AzureRoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -eq $machine.AzureRoleSize }
        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)'"
    }
    elseif ($machine.AzureProperties.RoleSize)
    {
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -eq $machine.AzureProperties.RoleSize }
        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)'"
    }
    elseif ($machine.AzureProperties.UseAllRoleSizes)
    {
        $DefaultAzureRoleSize = Get-LabConfigurationItem -Name DefaultAzureRoleSize
        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.MemoryInMB -ge $machine.Memory -and $_.NumberOfCores -ge $machine.Processors -and $machine.Disks.Count -le $_.MaxDataDiskCount } |
        Sort-Object -Property MemoryInMB, NumberOfCores |
        Select-Object -First 1

        Write-PSFMessage -Message "Using specified role size of '$($roleSize.InstanceSize)'. VM was configured to all role sizes but constrained to role size '$DefaultAzureRoleSize' by psd1 file"
    }
    else
    {
        $pattern = switch ($lab.AzureSettings.DefaultRoleSize)
        {
            'A' { '^(Standard_A\d{1,2}|Basic_A\d{1,2})' }
            'AS' { '^Standard_AS\d{1,2}' }
            'AC' { '^Standard_AC\d{1,2}' }
            'D' { '^Standard_D\d{1,2}' }
            'DS' { '^Standard_DS\d{1,2}' }
            'DC' { '^Standard_DC\d{1,2}' }
            "E" { '^Standard_E\d{1,2}' }
            "ES" { '^Standard_ES\d{1,2}' }
            "EC" { '^Standard_EC\d{1,2}' }
            'F' { '^Standard_F\d{1,2}' }
            'FS' { '^Standard_FS\d{1,2}' }
            'FC' { '^Standard_FC\d{1,2}' }
            'G' { '^Standard_G\d{1,2}' }
            'GS' { '^Standard_GS\d{1,2}' }
            'GC' { '^Standard_GC\d{1,2}' }
            'H' { '^Standard_H\d{1,2}' }
            'HS' { '^Standard_HS\d{1,2}' }
            'HC' { '^Standard_HC\d{1,2}' }
            'L' { '^Standard_L\d{1,2}' }
            'LS' { '^Standard_LS\d{1,2}' }
            'LC' { '^Standard_LC\d{1,2}' }
            'N' { '^Standard_N\d{1,2}' }
            'NS' { '^Standard_NS\d{1,2}' }
            'NC' { '^Standard_NC\d{1,2}' }
            default { '^(Standard_A\d{1,2}|Basic_A\d{1,2})' }
        }

        $roleSize = $lab.AzureSettings.RoleSizes |
        Where-Object { $_.Name -Match $pattern -and $_.Name -notlike '*promo*' } |
        Where-Object { $_.MemoryInMB -ge ($machine.Memory / 1MB) -and $_.NumberOfCores -ge $machine.Processors } |
        Sort-Object -Property MemoryInMB, NumberOfCores, @{ Expression = { if ($_.Name -match '.+_v(?<Version>\d{1,2})') { $Matches.Version } }; Ascending = $false } |
        Select-Object -First 1

        Write-PSFMessage -Message "Using specified role size of '$($roleSize.Name)' out of role sizes '$pattern'"
    }

    $roleSize
}

function Get-LWAzureSku
{
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine]$Machine
    )

    $lab = Get-Lab

    #if this machine has a SQL Server role
    foreach ($role in $Machine.Roles)
    {
        if ($role.Name -match 'SQLServer(?<SqlVersion>\d{4})')
        {
            #get the SQL Server version defined in the role
            $sqlServerRoleName = $Matches[0]
            $sqlServerVersion = $Matches.SqlVersion

            if ($role.Properties.Keys | Where-Object { $_ -ne 'InstallSampleDatabase' })
            {
                $useStandardVm = $true
            }
        }

        if ($role.Name -match 'VisualStudio(?<Version>\d{4})')
        {
            $visualStudioRoleName = $Matches[0]
            $visualStudioVersion = $Matches.Version
        }
    }

    if ($sqlServerRoleName -and -not $useStandardVm)
    {
        Write-PSFMessage -Message 'This is going to be a SQL Server VM'
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
        $offerName = $vmImageName = $vmImage.Offer
        $publisherName = $vmImage.PublisherName
        $skusName = $vmImage.Skus

        if (-not $vmImageName)
        {
            Write-ScreenInfo 'SQL Server image could not be found. The following combinations are currently supported by Azure:' -Type Warning
            foreach ($sqlServerImage in $sqlServerImages)
            {
                Write-PSFMessage -Level Host $sqlServerImage.Offer
            }

            throw "There is no Azure VM image for '$sqlServerRoleName' on operating system '$($machine.OperatingSystem)'. The machine cannot be created. Cancelling lab setup. Please find the available images above."
        }
    }
    elseif ($visualStudioRoleName)
    {
        Write-PSFMessage -Message 'This is going to be a Visual Studio VM'

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
        $offerName = $vmImageName = ($vmImage).Offer
        $publisherName = ($vmImage).PublisherName
        $skusName = ($vmImage).Skus

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

        $offerName = $vmImageName = ($vmImage).Offer
        $publisherName = ($vmImage).PublisherName
        $skusName = ($vmImage).Skus
    }

    Write-PSFMessage -Message "We selected the SKUs $skusName from offer $offerName by publisher $publisherName"
    @{
        offer     = $offerName
        publisher = $publisherName
        sku       = $skusName
        version   = 'latest'
    }
}

#region New-LWAzureVM
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
#endregion New-LWAzureVM

#region Initialize-LWAzureVM
function Initialize-LWAzureVM
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$Machine
    )

    Test-LabHostConnected -Throw -Quiet
    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $lab = Get-Lab

    $initScript = {
        param(
            [string]
            $UserLocale,

            [string]
            $TimeZoneId,

            [string]
            $Disks,

            [string]
            $LabSourcesPath,

            [string]
            $StorageAccountName,

            [string]
            $StorageAccountKey,

            [string[]]
            $DnsServers,

            [int]
            $WinRmMaxEnvelopeSizeKb,

            [int]
            $WinRmMaxConcurrentOperationsPerUser,

            [int]
            $WinRmMaxConnections,

            [string]
            $PublicKey
        )

        $defaultSettings = @{
            WinRmMaxEnvelopeSizeKb              = 500
            WinRmMaxConcurrentOperationsPerUser = 1500
            WinRmMaxConnections                 = 300
        }

        $null = mkdir C:\DeployDebug -ErrorAction SilentlyContinue
        $null = Start-Transcript -OutputDirectory C:\DeployDebug
    
        Start-Service WinRm
        foreach ($setting in $defaultSettings.GetEnumerator())
        {
            if ($PSBoundParameters[$setting.Key].Value -ne $setting.Value)
            {
                $subdir = if ($setting.Key -match 'MaxEnvelope') { $null } else { 'Service\' }
                Set-Item "WSMAN:\localhost\$subdir$($setting.Key.Replace('WinRm',''))" $($PSBoundParameters[$setting.Key]) -Force
            }
        }

        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        Enable-WSManCredSSP -Role Server -Force

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

        try
        {
            $geoId = [System.Globalization.RegionInfo]::new($UserLocale).GeoId
        }
        catch
        {
            $geoId = 244 #default is US
        }

        if (-not (Test-Path 'C:\AL'))
        {
            $alDir = New-Item -ItemType Directory -Path C:\AL -Force
        }

        $alDir = 'C:\AL'

        $tempFile = Join-Path -Path $alDir -ChildPath RegionalSettings
        $regionSettings -f $UserLocale, $geoId | Out-File -FilePath $tempFile
        $argument = 'intl.cpl,,/f:"{0}"' -f $tempFile
        control.exe $argument
        Start-Sleep -Seconds 1

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

        $idx = (Get-NetIPInterface | Where-object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*" }).ifIndex
        $dnsServer = Get-DnsClientServerAddress -InterfaceIndex $idx -AddressFamily IPv4
        Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses 168.63.129.16
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/powershell/releases/latest' -UseBasicParsing -ErrorAction SilentlyContinue
        $uri = ($release.assets | Where-Object name -like '*-win-x64.msi').browser_download_url
        if (-not $uri)
        {
            $uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi'
        }
    
        Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile C:\PS7.msi -ErrorAction SilentlyContinue    
        Start-Process -Wait -FilePath msiexec '/package C:\PS7.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=0 USE_MU=0 ENABLE_MU=0' -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        Remove-Item -Path C:\PS7.msi -ErrorAction SilentlyContinue

        # Configure SSHD for PowerShell Remoting alternative that also works on Linux
        if (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*')
        {
            Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue
            Start-Service sshd -ErrorAction SilentlyContinue
            Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction SilentlyContinue

            if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) 
            {
                New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any
            }

            New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\powershell\7\pwsh.exe" -PropertyType String -Force -ErrorAction SilentlyContinue
            $null = New-Item -Force -Path C:\AL\SSH -ItemType Directory
            if ($PublicKey) { $PublicKey | Set-Content -Path (Join-Path -Path C:\AL\SSH -ChildPath 'keys') }
            Start-Process -Wait -FilePath icacls.exe -ArgumentList "$(Join-Path -Path C:\AL\SSH -ChildPath 'keys') /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""" -ErrorAction SilentlyContinue
            $sshdConfig = @"
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
GSSAPIAuthentication yes
AllowGroups Users Administrators
AuthorizedKeysFile c:/al/ssh/keys
Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo
"@
            $sshdConfig | Set-Content -Path (Join-Path -Path $env:ProgramData -ChildPath 'ssh/sshd_config') -ErrorAction SilentlyContinue    
            Restart-Service -Name sshd -ErrorAction SilentlyContinue    
        }

        Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $dnsServer.ServerAddresses

        #Set Power Scheme to High Performance
        powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

        #Create a scheduled tasks that maps the Azure lab sources drive during each logon
        if (-not [string]::IsNullOrWhiteSpace($LabSourcesPath))
        {
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

            $cmdkeyTarget = ($LabSourcesPath -split '\\')[2]
            $script = $script -f $LabSourcesPath, $cmdkeyTarget, $StorageAccountName, $StorageAccountKey

            [pscustomobject]@{
                Path               = $LabSourcesPath
                StorageAccountName = $StorageAccountName
                StorageAccountKey  = $StorageAccountKey
            } | Export-Clixml -Path C:\AL\LabSourcesStorageAccount.xml
            $script | Out-File C:\AL\AzureLabSources.ps1 -Force
        }

        #set the time zone
        Set-TimeZone -Name $TimeZoneId

        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager\oobe' /v DoNotOpenInitialConfigurationTasksAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\ServerManager' /v DoNotOpenServerManagerAtLogon /d 1 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v EnableFirstLogonAnimation /d 0 /t REG_DWORD /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v FilterAdministratorToken /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v EnableLUA /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable admin IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v IsInstalled /t REG_DWORD /d 0 /f #disable user IE Enhanced Security Configuration
        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v BgInfo /t REG_SZ /d "C:\AL\BgInfo.exe C:\AL\BgInfo.bgi /Timer:0 /nolicprompt" /f

        #turn off the Windows firewall
        Set-NetFirewallProfile -All -Enabled False -PolicyStore PersistentStore

        if ($DnsServers.Count -gt 0)
        {
            Write-Verbose "Configuring $($DnsServers.Count) DNS Servers"
            $idx = (Get-NetIPInterface | Where-object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*" }).ifIndex
            Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $DnsServers
        }

        if (-not $Disks) { $null = try { Stop-Transcript -ErrorAction Stop } catch { }; return }
        
        # Azure InvokeRunAsCommand is not very clever, so we sent the stuff as JSON
        $Disks | Set-Content -Path C:\AL\disks.json
        [object[]] $diskObjects = $Disks | ConvertFrom-Json
        Write-Verbose -Message "Disk count for $env:COMPUTERNAME`: $($diskObjects.Count)"
        foreach ($diskObject in $diskObjects.Where({ -not $_.SkipInitialization }))
        {
            $disk = Get-Disk | Where-Object Location -like "*LUN $($diskObject.LUN)"
            $disk | Set-Disk -IsReadOnly $false
            $disk | Set-Disk -IsOffline $false
            $disk | Initialize-Disk -PartitionStyle GPT
            $party = if ($diskObject.DriveLetter)
            {
                $disk | New-Partition -UseMaximumSize -DriveLetter $diskObject.DriveLetter
            }
            else
            {
                $disk | New-Partition -UseMaximumSize -AssignDriveLetter
            }
            $party | Format-Volume -Force -UseLargeFRS:$diskObject.UseLargeFRS -AllocationUnitSize $diskObject.AllocationUnitSize -NewFileSystemLabel $diskObject.Label
        }

        $null = try { Stop-Transcript -ErrorAction Stop } catch { }
    }

    $initScriptFile = New-Item -ItemType File -Path (Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($Lab.Name)vminit.ps1") -Force
    $initScript.ToString() | Set-Content -Path $initScriptFile -Force

    # Configure AutoShutdown
    if ($lab.AzureSettings.AutoShutdownTime)
    {
        $time = $lab.AzureSettings.AutoShutdownTime
        $tz = if (-not $lab.AzureSettings.AutoShutdownTimeZone) { Get-TimeZone } else { Get-TimeZone -Id $lab.AzureSettings.AutoShutdownTimeZone }
        Write-ScreenInfo -Message "Configuring auto-shutdown of all VMs daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName (Get-LabVm | Where-Object Name -notin $machineSpecific.Name) -Time $time -TimeZone $tz.Id -Wait
    }

    $machineSpecific = Get-LabVm -SkipConnectionInfo | Where-Object {
        $_.AzureProperties.ContainsKey('AutoShutdownTime')
    }

    foreach ($machine in $machineSpecific)
    {
        $time = $machine.AzureProperties.AutoShutdownTime
        $tz = if (-not $machine.AzureProperties.AutoShutdownTimezoneId) { Get-TimeZone } else { Get-TimeZone -Id $machine.AzureProperties.AutoShutdownTimezoneId }
        Write-ScreenInfo -Message "Configure shutdown of $machine daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName $machine -Time $time -TimeZone $tz.Id -Wait
    }

    Write-ScreenInfo -Message 'Configuring localization and additional disks' -TaskStart -NoNewLine
    if (-not $lab.AzureSettings.IsAzureStack) { $labsourcesStorage = Get-LabAzureLabSourcesStorage }
    $jobs = foreach ($m in $Machine)
    {
        [string[]]$DnsServers = ($m.NetworkAdapters | Where-Object { $_.VirtualSwitch.Name -eq $Lab.Name }).Ipv4DnsServers.AddressAsString
        $azVmDisks = (Get-AzVm -Name $m.ResourceName -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName).StorageProfile.DataDisks
        foreach ($machDisk in $m.Disks)
        {
            $machDisk.Lun = $azVmDisks.Where({ $_.Name -eq $machDisk.Name }).Lun
        }
        
        $diskJson = $m.disks | ConvertTo-Json -Compress

        $scriptParam = @{
            UserLocale                          = $m.UserLocale
            TimeZoneId                          = $m.TimeZone
            WinRmMaxEnvelopeSizeKb              = Get-LabConfigurationItem -Name WinRmMaxEnvelopeSizeKb
            WinRmMaxConcurrentOperationsPerUser = Get-LabConfigurationItem -Name WinRmMaxConcurrentOperationsPerUser
            WinRmMaxConnections                 = Get-LabConfigurationItem -Name WinRmMaxConnections
        }
        $azsArgumentLine = '-UserLocale "{0}" -TimeZoneId "{1}" -WinRmMaxEnvelopeSizeKb {2} -WinRmMaxConcurrentOperationsPerUser {3} -WinRmMaxConnections {4}' -f $m.UserLocale, $m.TimeZone, (Get-LabConfigurationItem -Name WinRmMaxEnvelopeSizeKb), (Get-LabConfigurationItem -Name WinRmMaxConcurrentOperationsPerUser), (Get-LabConfigurationItem -Name WinRmMaxConnections)

        if ($DnsServers.Count -gt 0)
        {
            $scriptParam.DnsServers = $DnsServers
            $azsArgumentLine += ' -DnsServers "{0}"' -f ($DnsServers -join '","')
        }

        if ($m.SshPublicKey)
        {
            $scriptParam.PublicKey = $m.SshPublicKey
            $azsArgumentLine += ' -PublicKey "{0}"' -f $m.SshPublicKey
        }

        if ($diskJson)
        {
            $scriptParam.Disks = $diskJson
            $azsArgumentLine += " -Disks '{0}'" -f $diskJson
        }

        if ($labsourcesStorage)
        {            
            $scriptParam.LabSourcesPath = $labsourcesStorage.Path
            $scriptParam.StorageAccountName = $labsourcesStorage.StorageAccountName
            $scriptParam.StorageAccountKey = $labsourcesStorage.StorageAccountKey
            $azsArgumentLine += '-LabSourcesPath {0} -StorageAccountName {1} -StorageAccountKey {2}' -f $labsourcesStorage.Path, $labsourcesStorage.StorageAccountName, $labsourcesStorage.StorageAccountKey
        }

        if ($m.IsDomainJoined)
        {
            $domain = $lab.Domains | Where-Object Name -eq $m.DomainName
        }

        # Azure Stack - Create temporary storage account to upload script and use extension - sad, but true.
        if ($Lab.AzureSettings.IsAzureStack)
        {
            $sa = Get-AzStorageAccount -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $sa)
            {
                $sa = New-AzStorageAccount -Name "cse$(-join (1..10 | % {[char](Get-Random -Min 97 -Max 122)}))" -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -SkuName Standard_LRS -Kind Storage -Location (Get-LabAzureDefaultLocation).Location
            }

            $co = $sa | Get-AzStorageContainer -Name customscriptextension -ErrorAction SilentlyContinue
            if (-not $co)
            {
                $co = $sa | New-AzStorageContainer -Name customscriptextension
            }

            $content = Set-AzStorageBlobContent -File $initScriptFile -CloudBlobContainer $co.CloudBlobContainer -Blob $(Split-Path -Path $initScriptFile -Leaf) -Context $sa.Context -Force -ErrorAction Stop
            $token = New-AzStorageBlobSASToken -CloudBlob $content.ICloudBlob -StartTime (Get-Date) -ExpiryTime $(Get-Date).AddHours(1) -Protocol HttpsOnly -Context $sa.Context -Permission r -ErrorAction Stop
            $uri = '{0}{1}/{2}{3}' -f $co.Context.BlobEndpoint, 'customscriptextension', $(Split-Path -Path $initScriptFile -Leaf), $token
            [version] $typehandler = (Get-AzVMExtensionImage -PublisherName Microsoft.Compute -Type CustomScriptExtension -Location (Get-LabAzureDefaultLocation).Location | Sort-Object { [version]$_.Version } | Select-Object -Last 1).Version
            
            $extArg = @{
                ResourceGroupName  = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
                VMName             = $m.ResourceName
                FileUri            = $uri
                TypeHandlerVersion = '{0}.{1}' -f $typehandler.Major, $typehandler.Minor
                Name               = 'initcustomizations'
                Location           = (Get-LabAzureDefaultLocation).Location
                Run                = Split-Path -Path $initScriptFile -Leaf
                Argument           = $azsArgumentLine
                NoWait             = $true
            }
            $Null = Set-AzVMCustomScriptExtension @extArg
        }
        else
        {
            Invoke-AzVMRunCommand -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $m.ResourceName -ScriptPath $initScriptFile -Parameter $scriptParam -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob
        }
    }

    $initScriptFile | Remove-Item -ErrorAction SilentlyContinue

    if ($jobs)
    {
        Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 30 -NoDisplay
    }

    # Wait for VM extensions to be "done"
    if ($lab.AzureSettings.IsAzureStack)
    {
        $extensionStatuus = Get-LabVm | Foreach-Object { Get-AzVMCustomScriptExtension -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $_.ResourceName -Name initcustomizations -ErrorAction SilentlyContinue }
        $start = Get-Date
        $timeout = New-TimeSpan -Minutes 5
        while (($extensionStatuus.ProvisioningState -contains 'Updating' -or $extensionStatuus.ProvisioningState -contains 'Creating') -and ((Get-Date) - $start) -lt $timeout)
        {
            Start-Sleep -Seconds 5
            $extensionStatuus = Get-LabVm | Foreach-Object { Get-AzVMCustomScriptExtension -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $_.ResourceName -Name initcustomizations -ErrorAction SilentlyContinue }
        }

        foreach ($network in $Lab.VirtualNetworks)
        {
            if ($network.DnsServers.Count -eq 0) { continue }
            $vnet = Get-AzVirtualNetwork -Name $network.ResourceName -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
            $vnet.dhcpOptions.dnsServers = [string[]]($network.DnsServers.AddressAsString)
            $null = $vnet | Set-AzVirtualNetwork
        }
    }
    Install-LabSshKnownHost
    Copy-LabFileItem -Path (Get-ChildItem -Path "$((Get-Module -Name AutomatedLab)[0].ModuleBase)\Tools\HyperV\*") -DestinationFolderPath /AL -ComputerName $Machine -UseAzureLabSourcesOnAzureVm $false
    Send-ModuleToPSSession -Module (Get-Module -ListAvailable -Name AutomatedLab.Common | Select-Object -First 1) -Session (New-LabPSSession $Machine) -IncludeDependencies -Force
    Write-ScreenInfo -Message 'Finished' -TaskEnd

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

    Write-PSFMessage "Removing all sessions after VmInit"
    Remove-LabPSSession

    Write-LogFunctionExit
}
#endregion Initialize-LWAzureVM


#region Remove-LWAzureVM
function Remove-LWAzureVM
{
    Param (
        [Parameter(Mandatory)]
        [string]$Name,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $Lab = Get-Lab
    $vm = Get-AzVM -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
    $null = $vm | Remove-AzVM -Force
    foreach ($loadBalancer in (Get-AzLoadBalancer -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName))
    {
        $rules = $loadBalancer | Get-AzLoadBalancerInboundNatRuleConfig | Where-Object Name -like "$($Name)*"
        foreach ($rule in $rules)
        {
            $null = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $loadBalancer -Name $rule.Name -Confirm:$false
        }
    }

    $vmResources = Get-AzResource -ResourceGroupName $Lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Name "$($name)*"
    $jobs = $vmResources | Remove-AzResource -AsJob -Force -Confirm:$false

    if (-not $AsJob.IsPresent)
    {
        $null = $jobs | Wait-Job
    }

    if ($PassThru.IsPresent)
    {
        $jobs
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

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $machines = Get-LabVm -ComputerName $ComputerName

    $azureVms = Get-LWAzureVm -ComputerName $ComputerName

    $stoppedAzureVms = $azureVms | Where-Object { $_.PowerState -ne 'VM running' -and $_.Name -in $machines.ResourceName }

    $lab = Get-Lab

    $machinesToJoin = @()

    if ($stoppedAzureVms)
    {
        $jobs = foreach ($name in $machines.ResourceName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Start-AzVM -AsJob
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
    }

    # Refresh status
    $azureVms = Get-LWAzureVm -ComputerName $ComputerName

    $azureVms = $azureVms | Where-Object { $_.Name -in $machines.ResourceName }

    foreach ($machine in $machines)
    {
        $vm = $azureVms | Where-Object Name -eq $machine.ResourceName

        if ($vm.PowerState -ne 'VM Running')
        {
            throw "Could not start machine '$machine'"
        }
        else
        {
            if ($machine.IsDomainJoined -and -not $machine.HasDomainJoined -and ($machine.Roles.Name -notcontains 'RootDC' -and $machine.Roles.Name -notcontains 'FirstChildDC' -and $machine.Roles.Name -notcontains 'DC'))
            {
                $machinesToJoin += $machine
            }
        }
    }

    if ($machinesToJoin)
    {
        Write-PSFMessage -Message "Waiting for machines '$($machinesToJoin -join ', ')' to come online"
        Wait-LabVM -ComputerName $machinesToJoin -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine

        Write-PSFMessage -Message 'Start joining the machines to the respective domains'
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
        [string[]]
        $ComputerName,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]
        $NoNewLine,

        [switch]
        $ShutdownFromOperatingSystem,

        [bool]
        $StayProvisioned = $false
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

    $lab = Get-Lab
    $machines = Get-LabVm -ComputerName $ComputerName -IncludeLinux
    $azureVms = Get-AzVM -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName

    $azureVms = $azureVms | Where-Object { $_.Name -in $machines.ResourceName }

    if ($ShutdownFromOperatingSystem)
    {
        $jobs = @()
        $linux, $windows = $machines.Where( { $_.OperatingSystemType -eq 'Linux' }, 'Split')

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
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$($failedJobs.Location)'" -Type Error
        }
    }
    else
    {
        $jobs = foreach ($name in $machines.ResourceName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Stop-AzVM -Force -StayProvisioned:$StayProvisioned -AsJob
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object { $_.State -eq 'Failed' }
        if ($failedJobs)
        {
            $jobNames = ($failedJobs | ForEach-Object {
                    if ($_.Name.StartsWith("StopAzureVm_"))
                    {
                        ($_.Name -split "_")[1]
                    }
                    elseif ($_.Name -match "Long Running Operation for 'Stop-AzVM' on resource '(?<MachineName>[\w-]+)'")
                    {
                        $Matches.MachineName
                    }
                }) -join ", "

            Write-ScreenInfo -Message "Could not stop Azure VM(s): '$jobNames'" -Type Error
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

    Test-LabHostConnected -Throw -Quiet

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $start = $MonitoringStartTime.ToUniversalTime()

    Write-PSFMessage -Message "Starting monitoring the servers at '$start'"

    $machines = Get-LabVM -ComputerName $ComputerName

    $cmd = {
        param (
            [datetime]$Start
        )

        $Start = $Start.ToLocalTime()

        (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootupTime -ge $Start
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

            $hasRestarted = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -UseLocalCredential -DoNotUseCredSsp:$DoNotUseCredSsp -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if (-not $hasRestarted)
            {
                $events = Invoke-LabCommand -ComputerName $machine -ActivityName WaitForRestartEvent -ScriptBlock $cmd -ArgumentList $start.Ticks -DoNotUseCredSsp:$DoNotUseCredSsp -PassThru -Verbose:$false -NoDisplay -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            if ($hasRestarted)
            {
                Write-PSFMessage -Message "VM '$machine' has been restarted"
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

    Write-PSFMessage -Message "Finished monitoring the servers at '$(Get-Date)'"

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

    Test-LabHostConnected -Throw -Quiet

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $result = @{ }
    $azureVms = Get-LWAzureVm @PSBoundParameters

    $resourceGroups = (Get-LabVM).AzureConnectionInfo.ResourceGroupName | Select-Object -Unique
    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName -and $_.ResourceGroupName -in $resourceGroups }

    $vmTable = @{ }
    Get-LabVm -IncludeLinux | Where-Object FriendlyName -in $ComputerName | ForEach-Object { $vmTable[$_.FriendlyName] = $_.Name }

    foreach ($azureVm in $azureVms)
    {
        $vmName = if ($vmTable[$azureVm.Name]) { $vmTable[$azureVm.Name] } else { $azureVm.Name }
        if ($azureVm.PowerState -eq 'VM running')
        {
            $result.Add($vmName, 'Started')
        }
        elseif ($azureVm.PowerState -eq 'VM stopped' -or $azureVm.PowerState -eq 'VM deallocated')
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
#endregion Get-LWAzureVMStatus

#region Get-LWAzureVMConnectionInfo
function Get-LWAzureVMConnectionInfo
{
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Machine[]]$ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $lab = Get-Lab -ErrorAction SilentlyContinue
    $retryCount = 5

    if (-not $lab)
    {
        Write-PSFMessage "Could not retrieve machine info for '$($ComputerName.Name -join ',')'. No lab was imported."
    }

    if (-not ((Get-AzContext).Subscription.Name -eq $lab.AzureSettings.DefaultSubscription))
    {
        Set-AzContext -Subscription $lab.AzureSettings.DefaultSubscription
    }

    $resourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $azureVMs = Get-AzVM | Where-Object ResourceGroupName -in (Get-LabAzureResourceGroup).ResourceGroupName | Where-Object Name -in $ComputerName.ResourceName

    foreach ($name in $ComputerName)
    {
        $azureVM = $azureVMs | Where-Object Name -eq $name.ResourceName

        if (-not $azureVM)
        { continue }

        $net = $lab.VirtualNetworks.Where({ $_.Name -eq $name.Network[0] })
        $ip = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue | Where-Object { $_.Tag['Vnet'] -eq $net.ResourceName }

        if (-not $ip)
        {
            $ip = Get-AzPublicIpAddress -Name "$($resourceGroupName)$($net.ResourceName)lbfrontendip" -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
        }

        $result = [AutomatedLab.Azure.AzureConnectionInfo] @{
            ComputerName      = $name.Name
            DnsName           = $ip.DnsSettings.Fqdn
            HttpsName         = $ip.DnsSettings.Fqdn
            VIP               = $ip.IpAddress
            Port              = $name.LoadBalancerWinrmHttpPort
            HttpsPort         = $name.LoadBalancerWinrmHttpsPort
            RdpPort           = $name.LoadBalancerRdpPort
            SshPort           = $name.LoadBalancerSshPort
            ResourceGroupName = $azureVM.ResourceGroupName
        }

        Write-PSFMessage "Get-LWAzureVMConnectionInfo created connection info for VM '$name'"
        Write-PSFMessage "ComputerName      = $($name.Name)"
        Write-PSFMessage "DnsName           = $($ip.DnsSettings.Fqdn)"
        Write-PSFMessage "HttpsName         = $($ip.DnsSettings.Fqdn)"
        Write-PSFMessage "VIP               = $($ip.IpAddress)"
        Write-PSFMessage "Port              = $($name.LoadBalancerWinrmHttpPort)"
        Write-PSFMessage "HttpsPort         = $($name.LoadBalancerWinrmHttpsPort)"
        Write-PSFMessage "RdpPort           = $($name.LoadBalancerRdpPort)"
        Write-PSFMessage "SshPort           = $($name.LoadBalancerSshPort)"
        Write-PSFMessage "ResourceGroupName = $($azureVM.ResourceGroupName)"

        $result
    }

    Write-LogFunctionExit -ReturnValue $result
}
#endregion Get-LWAzureVMConnectionInfo

#region Enable-LWAzureVMRemoting
function Enable-LWAzureVMRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not enabling CredSSP a third time on Linux")]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [switch]$UseSSL
    )

    Test-LabHostConnected -Throw -Quiet

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

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
                -ArgumentList $machine.DomainName, $cred.UserName, $cred.GetNetworkCredential().Password -ErrorAction Stop -UseLocalCredential
        }
        catch
        {
            if ($IsLinux)
            {
                return
            }

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

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $lab = Get-Lab
    $jobs = @()

    $tempFileName = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath enableazurewinrm.labtempfile.ps1
    $customScriptContent = @'
$null = mkdir C:\DeployDebug -ErrorAction SilentlyContinue
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
        if ($Lab.AzureSettings.IsAzureStack)
        {
            $sa = Get-AzStorageAccount -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $sa)
            {
                $sa = New-AzStorageAccount -Name "cse$(-join (1..10 | % {[char](Get-Random -Min 97 -Max 122)}))" -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -SkuName Standard_LRS -Kind Storage -Location (Get-LabAzureDefaultLocation).Location
            }

            $co = $sa | Get-AzStorageContainer -Name customscriptextension -ErrorAction SilentlyContinue
            if (-not $co)
            {
                $co = $sa | New-AzStorageContainer -Name customscriptextension
            }

            $content = Set-AzStorageBlobContent -File $tempFileName -CloudBlobContainer $co.CloudBlobContainer -Blob $(Split-Path -Path $tempFileName -Leaf) -Context $sa.Context -Force -ErrorAction Stop
            $token = New-AzStorageBlobSASToken -CloudBlob $content.ICloudBlob -StartTime (Get-Date) -ExpiryTime $(Get-Date).AddHours(1) -Protocol HttpsOnly -Context $sa.Context -Permission r -ErrorAction Stop
            $uri = '{0}{1}/{2}{3}' -f $co.Context.BlobEndpoint, 'customscriptextension', $(Split-Path -Path $tempFileName -Leaf), $token
            [version] $typehandler = (Get-AzVMExtensionImage -PublisherName Microsoft.Compute -Type CustomScriptExtension -Location (Get-LabAzureDefaultLocation).Location | Sort-Object { [version]$_.Version } | Select-Object -Last 1).Version
            
            $extArg = @{
                ResourceGroupName  = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
                VMName             = $m.ResourceName
                FileUri            = $uri
                TypeHandlerVersion = '{0}.{1}' -f $typehandler.Major, $typehandler.Minor
                Name               = 'initcustomizations'
                Location           = (Get-LabAzureDefaultLocation).Location
                Run                = Split-Path -Path $tempFileName -Leaf
                NoWait             = $true
            }
            $Null = Set-AzVMCustomScriptExtension @extArg
        }
        else
        {
            Invoke-AzVMRunCommand -ResourceGroupName $rgName -VMName $m.ResourceName -ScriptPath $tempFileName -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob
        }
    }

    if ($Wait)
    {
        Wait-LWLabJob -Job $jobs

        $results = $jobs | Receive-Job -Keep -ErrorAction SilentlyContinue -ErrorVariable +AL_AzureWinrmActivationErrors
        $failedJobs = $jobs | Where-Object -Property Status -eq 'Failed'

        if ($failedJobs)
        {
            $machineNames = $($($failedJobs).Name -replace "'").ForEach( { $($_ -split '\s')[-1] })
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

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $labSourcesStorageAccount = Get-LabAzureLabSourcesStorage -ErrorAction SilentlyContinue

    if ($Session.Runspace.ConnectionInfo.AuthenticationMechanism -notin 'CredSsp', 'Negotiate' -or -not $labSourcesStorageAccount)
    {
        return
    }

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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not relevant, used in Invoke-LabCommand")]
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

    Test-LabHostConnected -Throw -Quiet

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $azureIsoPath = $IsoPath -replace '/', '\' -replace 'https:'
    # ISO file should already exist on Azure storage share, as it was initially retrieved from there as well.

    # Path is local (usually Azure Stack which has no storage file shares)
    if (-not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $azureIsoPath))
    {
        Write-ScreenInfo -type Info -Message "Copying $azureIsoPath to $($ComputerName -join ',')"
        Copy-LabFileItem -Path $azureIsoPath -ComputerName $ComputerName -DestinationFolderPath C:\ALMounts
        $result = Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName -join ',')" -ComputerName $ComputerName -ScriptBlock {
            $drive = Mount-DiskImage -ImagePath C:\ALMounts\$(Split-Path -Leaf -Path $azureIsoPath) -StorageType ISO -PassThru | Get-Volume
            $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
            $drive | Add-Member -MemberType NoteProperty -Name InternalComputerName -Value $env:COMPUTERNAME -Force
            $drive | Select-Object -Property *
        } -Variable (Get-Variable azureIsoPath) -PassThru:$PassThru.IsPresent

        if ($PassThru.IsPresent) { return $result } else { return }
    }

    Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName -join ',')" -ComputerName $ComputerName -ScriptBlock {

        if (-not (Test-Path -Path $azureIsoPath))
        {
            throw "'$azureIsoPath' is not accessible."
        }

        $drive = Mount-DiskImage -ImagePath $azureIsoPath -StorageType ISO -PassThru | Get-Volume
        $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
        $drive | Add-Member -MemberType NoteProperty -Name InternalComputerName -Value $env:COMPUTERNAME -Force
        $drive | Select-Object -Property *

    } -ArgumentList $azureIsoPath -Variable (Get-Variable -Name azureIsoPath) -PassThru:$PassThru
}
#endregion

#region Dismount-LWAzureIsoImage
function Dismount-LWAzureIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not relevant, used in Invoke-LabCommand")]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Dismounting ISO Images on Azure machines $($ComputerName -join ',')" -ScriptBlock {

        Get-Volume | 
        Where-Object DriveType -eq CD-ROM |
        ForEach-Object {
            Get-DiskImage -DevicePath $_.Path.TrimEnd('\') -ErrorAction SilentlyContinue
        } |
        ForEach-Object {
            Write-Verbose -Message "Dismounting '$($_.ImagePath)'"
            $_ | Dismount-DiskImage
        }

        Get-ChildItem -Path C:\ALMounts\*.iso -ErrorAction SilentlyContinue | Remove-Item
    } -NoDisplay
}
#endregion

#region Checkpoint-LWAzureVM
function Checkpoint-LWAzureVM
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab
    $resourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    $runningMachines = Get-LabVM -IsRunning -ComputerName $ComputerName
    if ($runningMachines)
    {
        Stop-LWAzureVM -ComputerName $runningMachines -StayProvisioned $true
        Wait-LabVMShutdown -ComputerName $runningMachines
    }

    $jobs = foreach ($machine in $ComputerName)
    {
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $machine -ErrorAction SilentlyContinue
        if (-not $vm)
        {
            Write-ScreenInfo -Message "$machine could not be found in $($resourceGroupName). Skipping snapshot." -type Warning
            continue
        }

        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        $existingSnapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmSnapshotName -ErrorAction SilentlyContinue
        if ($existingSnapshot)
        {
            Write-ScreenInfo -Message "Snapshot $SnapshotName for $machine already exists as $($existingSnapshot.Name). Not creating it again." -Type Warning
            continue
        }

        $osSourceDisk = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
        $snapshotConfig = New-AzSnapshotConfig -SourceUri $osSourceDisk.Id -CreateOption Copy -Location $vm.Location
        New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $vmSnapshotName -ResourceGroupName $resourceGroupName -AsJob
    }

    if ($jobs.State -contains 'Failed')
    {
        Write-ScreenInfo -Type Error -Message "At least one snapshot creation failed: $($jobs.Name -join ',')."
        $skipRemove = $true
    }

    if ($jobs)
    {
        $null = $jobs | Wait-Job
        $jobs | Remove-Job
    }

    if ($runningMachines)
    {
        Start-LWAzureVM -ComputerName $runningMachines
        Wait-LabVM -ComputerName $runningMachines
    }

    Write-LogFunctionExit
}
#endregion

#region Restore-LWAzureVmSnapshot
function Restore-LWAzureVmSnapshot
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [string]$SnapshotName
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab
    $resourceGroupName = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName

    $runningMachines = Get-LabVM -IsRunning -ComputerName $ComputerName
    if ($runningMachines)
    {
        Stop-LWAzureVM -ComputerName $runningMachines -StayProvisioned $true
        Wait-LabVMShutdown -ComputerName $runningMachines
    }

    $vms = Get-AzVM -ResourceGroupName $resourceGroupName | Where-Object Name -In $ComputerName
    $machineStatus = @{}
    $ComputerName.ForEach( { $machineStatus[$_] = @{ Stage1 = $null; Stage2 = $null; Stage3 = $null } })

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $vmSnapshotName = '{0}_{1}' -f $machine, $SnapshotName
        if (-not $vm)
        {
            Write-ScreenInfo -Message "$machine could not be found in $($resourceGroupName). Skipping snapshot." -type Warning
            continue
        }

        $snapshot = Get-AzSnapshot -SnapshotName $vmSnapshotName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $snapshot)
        {
            Write-ScreenInfo -Message "No snapshot named $vmSnapshotName found for $machine. Skipping restore." -Type Warning
            continue
        }

        $osDiskName = $vm.StorageProfile.OsDisk.name
        $oldOsDisk = Get-AzDisk -Name $osDiskName -ResourceGroupName $resourceGroupName
        $disksToRemove += $oldOsDisk.Name
        $storageType = $oldOsDisk.sku.name
        $diskconf = New-AzDiskConfig -AccountType $storagetype -Location $oldOsdisk.Location -SourceResourceId $snapshot.Id -CreateOption Copy

        $machineStatus[$machine].Stage1 = @{
            VM      = $vm
            OldDisk = $oldOsDisk.Name
            Job     = New-AzDisk -Disk $diskconf -ResourceGroupName $resourceGroupName -DiskName "$($vm.Name)-$((New-Guid).ToString())" -AsJob
        }
    }

    if ($machineStatus.Values.Stage1.Job)
    {
        $null = $machineStatus.Values.Stage1.Job | Wait-Job
    }

    $failedStage1 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage1.Job.State -eq 'Failed' }).Name
    if ($failedStage1) { Write-ScreenInfo -Type Error -Message "The following machines failed to create a new disk from the snapshot: $($failedStage1 -join ',')" }

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage1.Job.State -eq 'Completed' }).Name

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $newDisk = $machineStatus[$machine].Stage1.Job | Receive-Job -Keep
        $null = Set-AzVMOSDisk -VM $vm -ManagedDiskId $newDisk.Id -Name $newDisk.Name
        $machineStatus[$machine].Stage2 = @{
            Job = Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm -AsJob
        }
    }

    if ($machineStatus.Values.Stage2.Job)
    {
        $null = $machineStatus.Values.Stage2.Job | Wait-Job
    }

    $failedStage2 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage2.Job.State -eq 'Failed' }).Name
    if ($failedStage2) { Write-ScreenInfo -Type Error -Message "The following machines failed to update with the new OS disk created from a snapshot: $($failedStage2 -join ',')" }

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage2.Job.State -eq 'Completed' }).Name

    foreach ($machine in $ComputerName)
    {
        $disk = $machineStatus[$machine].Stage1.OldDisk
        $machineStatus[$machine].Stage3 = @{
            Job = Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $disk -Confirm:$false -Force -AsJob
        }
    }
    if ($machineStatus.Values.Stage3.Job)
    {
        $null = $machineStatus.Values.Stage3.Job | Wait-Job
    }

    $failedStage3 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript { $_.Value.Stage3.Job.State -eq 'Failed' }).Name
    if ($failedStage3)
    {
        $failedDisks = $failedStage3.ForEach( { $machineStatus[$_].Stage1.OldDisk })
        Write-ScreenInfo -Type Warning -Message "The following machines failed to remove their old OS disk in a background job: $($failedStage3 -join ','). Trying to remove the disks again synchronously."

        foreach ($machine in $failedStage3)
        {
            $disk = $machineStatus[$machine].Stage1.OldDisk
            $null = Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $disk -Confirm:$false -Force
        }
    }

    if ($runningMachines)
    {
        Start-LWAzureVM -ComputerName $runningMachines
        Wait-LabVM -ComputerName $runningMachines
    }

    if ($machineStatus.Values.Values.Job)
    {
        $machineStatus.Values.Values.Job | Remove-Job
    }

    Write-LogFunctionExit
}
#endregion

#region Remove-LWAzureVmSnapshot
function Remove-LWAzureVmSnapshot
{
    [Cmdletbinding()]
    Param
    (
        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [Parameter(Mandatory, ParameterSetName = 'AllSnapshots')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'BySnapshotName')]
        [string]$SnapshotName,

        [Parameter(ParameterSetName = 'AllSnapshots')]
        [switch]$All
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $lab = Get-Lab

    $snapshots = Get-AzSnapshot -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

    if ($PSCmdlet.ParameterSetName -eq 'BySnapshotName')
    {
        $snapshotsToRemove = $ComputerName.Foreach( { '{0}_{1}' -f $_, $SnapshotName })
        $snapshots = $snapshots | Where-Object -Property Name -in $snapshotsToRemove
    }

    $null = $snapshots | Remove-AzSnapshot -Force -Confirm:$false

    Write-LogFunctionExit
}
#endregion

#region Get-LWAzureVmSnapshot
function Get-LWAzureVmSnapshot
{
    param
    (
        [Parameter()]
        [Alias('VMName')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [Alias('Name')]
        [string]
        $SnapshotName
    )

    Test-LabHostConnected -Throw -Quiet

    $snapshots = Get-AzSnapshot -ResourceGroupName (Get-LabAzureDefaultResourceGroup).Name -ErrorAction SilentlyContinue

    if ($SnapshotName)
    {
        $snapshots = $snapshots | Where-Object { ($_.Name -split '_')[1] -eq $SnapshotName }
    }

    if ($ComputerName)
    {
        $snapshots = $snapshots | Where-Object { ($_.Name -split '_')[0] -in $ComputerName }
    }

    $snapshots.ForEach({
            [AutomatedLab.Snapshot]::new(($_.Name -split '_')[1], ($_.Name -split '_')[0], $_.TimeCreated)
        })
}
#endregion

#region Get-LWAzureVm
function Get-LWAzureVm
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable getazvmerror
    $count = 1
    while (-not $azureVms -and $count -le $azureRetryCount)
    {
        Write-ScreenInfo -Type Verbose -Message "Get-AzVM did not return anything, attempt $count of $($azureRetryCount) attempts. Azure presented us with the error: $($getazvmerror.Exception.Message)"
        Start-Sleep -Seconds 2
        $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable getazvmerror
        $count++
    }

    if (-not $azureVms)
    {
        Write-ScreenInfo -Message "Get-AzVM did not return anything in $($azureRetryCount) attempts, stopping lab deployment. Azure presented us with the error: $($getazvmerror.Exception.Message)"
        throw "Get-AzVM did not return anything in $($azureRetryCount) attempts, stopping lab deployment. Azure presented us with the error: $($getazvmerror.Exception.Message)"
    }

    if ($ComputerName.Count -eq 0) { return $azureVms }
    $azureVms | Where-Object Name -in $ComputerName
}
#endregion

#region Autoshutdown
function Get-LWAzureAutoShutdown
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab -ErrorAction Stop
    $resourceGroup = $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName

    $schedules = (Get-AzResource -ResourceGroupName $resourceGroup -ResourceType Microsoft.DevTestLab/schedules -ExpandProperties -ErrorAction SilentlyContinue).Properties

    foreach ($schedule in $schedules)
    {
        $hour, $minute = Get-StringSection -SectionSize 2 -String $schedule.dailyRecurrence.time

        if ($schedule)
        {
            [PSCustomObject]@{
                ComputerName = ($schedule.targetResourceId -split '/')[-1]
                Time         = New-TimeSpan -Hours $hour -Minutes $minute
                TimeZone     = Get-TimeZone -Id $schedule.timeZoneId
            }
        }
    }
}

function Enable-LWAzureAutoShutdown
{
    param
    (
        [string[]]
        $ComputerName,

        [timespan]
        $Time,

        [string]
        $TimeZone = (Get-TimeZone).Id,

        [switch]
        $Wait
    )

    $lab = Get-Lab -ErrorAction Stop
    $labVms = Get-AzVm -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    if ($ComputerName)
    {
        $labVms = $labVms | Where-Object Name -in $ComputerName
    }
    $resourceIdString = '{0}/providers/microsoft.devtestlab/schedules/shutdown-computevm-' -f $lab.AzureSettings.DefaultResourceGroup.ResourceId

    $jobs = foreach ($vm in $labVms)
    {
        $properties = @{
            status           = 'Enabled'
            taskType         = 'ComputeVmShutdownTask'
            dailyRecurrence  = @{time = $Time.ToString('hhmm') }
            timeZoneId       = $TimeZone
            targetResourceId = $vm.Id
        }

        New-AzResource -ResourceId ("$($resourceIdString)$($vm.Name)") -Location $vm.Location -Properties $properties -Force -ErrorAction SilentlyContinue -AsJob
    }

    if ($jobs -and $Wait.IsPresent)
    {
        $null = $jobs | Wait-Job
    }
}

function Disable-LWAzureAutoShutdown
{
    param
    (
        [string[]]
        $ComputerName,

        [switch]
        $Wait
    )

    $lab = Get-Lab -ErrorAction Stop
    $labVms = Get-AzVm -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName
    if ($ComputerName)
    {
        $labVms = $labVms | Where-Object Name -in $ComputerName
    }
    $resourceIdString = '{0}/providers/microsoft.devtestlab/schedules/shutdown-computevm-' -f $lab.AzureSettings.DefaultResourceGroup.ResourceId

    $jobs = foreach ($vm in $labVms)
    {
        Remove-AzResource -ResourceId ("$($resourceIdString)$($vm.Name)") -Force -ErrorAction SilentlyContinue -AsJob
    }

    if ($jobs -and $Wait.IsPresent)
    {
        $null = $jobs | Wait-Job
    }
}
#endregion

#region Remove-LWAzureRecoveryServicesVault
function Remove-LWAzureRecoveryServicesVault
{
    [CmdletBinding()]
    param
    (
        [int]
        $RetryCount = 0
    )

    $lab = Get-Lab -ErrorAction SilentlyContinue
    if (-not $lab) { return }

    $rsVault = Get-AzResource -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -ResourceType Microsoft.RecoveryServices/vaults -ErrorAction SilentlyContinue
    if (-not $rsVault) { return }

    if (-not (Get-Module -ListAvailable -Name Az.RecoveryServices | Where-Object Version -ge '5.3.0'))
    {
        try
        {
            Install-Module -Force -Name Az.RecoveryServices -Repository PSGallery -MinimumVersion 5.3.0 -ErrorAction Stop
        }
        catch
        {
            Write-ScreenInfo -Type Error -Message "Unable to install Az.RecoveryServices, 5.3.0+. Please delete your RecoveryServices Vault $($rsVault.Id) yourself."
            return
        }
    }

    Write-LogFunctionEntry
    Write-ScreenInfo -Message "Removing recovery services vault $($rsVault.Id) in $($rsVault.ResourceGroupName) so that the resource group can be deleted properly. This takes a while."
    $vaultToDelete = Get-AzRecoveryServicesVault -Name $rsVault.ResourceName -ResourceGroupName $rsVault.ResourceGroupName
    $null = Set-AzRecoveryServicesAsrVaultContext -Vault $vaultToDelete

    $null = Set-AzRecoveryServicesVaultProperty -Vault $vaultToDelete.ID -SoftDeleteFeatureState Disable #disable soft delete
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vaultToDelete.ID | Where-Object { $_.DeleteState -eq "ToBeDeleted" } #fetch backup items in soft delete state
    foreach ($softitem in $containerSoftDelete)
    {
        $null = Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $vaultToDelete.ID -Force #undelete items in soft delete state
    }
    
    if ((Get-Command Set-AzRecoveryServicesVaultProperty).Parameters.ContainsKey('DisableHybridBackupSecurityFeature'))
    {
        $null = Set-AzRecoveryServicesVaultProperty -VaultId $vaultToDelete.ID -DisableHybridBackupSecurityFeature $true
    }

    #Fetch all protected items and servers
    # Collection of try/catches since some enum values might be invalid
    $backupItemsVM = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsSQL = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsAFS = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupItemsSAP = try { Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupContainersSQL = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.ExtendedInfo.WorkloadType -eq "SQL" } } catch {}
    $protectableItemsSQL = try { Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.IsAutoProtected -eq $true } } catch {}
    $backupContainersSAP = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.ExtendedInfo.WorkloadType -eq "SAPHana" } } catch {}
    $StorageAccounts = try { Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -Status Registered -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupServersMARS = try { Get-AzRecoveryServicesBackupContainer -ContainerType "Windows" -BackupManagementType MAB -VaultId $vaultToDelete.ID -ErrorAction Stop } catch {}
    $backupServersMABS = try { Get-AzRecoveryServicesBackupManagementServer -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.BackupManagementType -eq "AzureBackupServer" } } catch {}
    $backupServersDPM = try { Get-AzRecoveryServicesBackupManagementServer -VaultId $vaultToDelete.ID -ErrorAction Stop | Where-Object { $_.BackupManagementType -eq "SCDPM" } } catch {}
    $pvtendpoints = try { Get-AzPrivateEndpointConnection -PrivateLinkResourceId $vaultToDelete.ID -ErrorAction Stop } catch {}

    $pool = New-RunspacePool -Variable (Get-Variable vaultToDelete) -ThrottleLimit 20
    $jobs = [system.Collections.ArrayList]::new()

    foreach ($item in $backupItemsVM)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsSQL)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $protectableItems)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupContainersSQL)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsSAP)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupContainersSAP)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupItemsAFS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vaultToDelete.ID -RemoveRecoveryPoints -Force } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $StorageAccounts)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersMARS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersMABS)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    foreach ($item in $backupServersDPM)
    {
        $null = $jobs.Add((Start-RunspaceJob -ScriptBlock { param ($item) Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $vaultToDelete.ID } -RunspacePool $pool -Argument $item))
    }

    $null = Wait-RunspaceJob -RunspaceJob $jobs
    Remove-RunspacePool -RunspacePool $pool

    #Deletion of ASR Items
    $fabricObjects = Get-AzRecoveryServicesAsrFabric
    # First DisableDR all VMs.
    foreach ($fabricObject in $fabricObjects)
    {
        $containerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabricObject -ErrorAction SilentlyContinue
        foreach ($containerObject in $containerObjects)
        {
            $protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $containerObject -ErrorAction SilentlyContinue
            # DisableDR all protected items
            foreach ($protectedItem in $protectedItems)
            {
                $null = Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $protectedItem -Force
            }

            $containerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $containerObject
            # Remove all Container Mappings
            foreach ($containerMapping in $containerMappings)
            {
                $null = Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $containerMapping -Force
            }
        }
        $networkObjects = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject
        foreach ($networkObject in $networkObjects)
        {
            #Get the PrimaryNetwork
            $PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject -FriendlyName $networkObject
            $NetworkMappings = Get-AzRecoveryServicesAsrNetworkMapping -Network $PrimaryNetwork
            foreach ($networkMappingObject in $NetworkMappings)
            {
                #Get the Neetwork Mappings
                $NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $networkMappingObject.Name -Network $PrimaryNetwork
                $null = Remove-AzRecoveryServicesAsrNetworkMapping -InputObject $NetworkMapping
            }
        }
        # Remove Fabric
        $null = Remove-AzRecoveryServicesAsrFabric -InputObject $fabricObject -Force
    }

    foreach ($item in $pvtendpoints)
    {
        $penamesplit = $item.Name.Split(".")
        $pename = $penamesplit[0]
        $null = Remove-AzPrivateEndpointConnection -ResourceId $item.PrivateEndpoint.Id -Force #remove private endpoint connections
        $null = Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -Force #remove private endpoints
    }

    try
    {
        $null = Remove-AzRecoveryServicesVault -Vault $vaultToDelete -Confirm:$false -ErrorAction Stop
    }
    catch
    {
        if ($RetryCount -le 2)
        {
            Remove-LWAzureRecoveryServicesVault -RetryCount ($RetryCount + 1)
        }
    }
    Write-LogFunctionExit
}
#endregion