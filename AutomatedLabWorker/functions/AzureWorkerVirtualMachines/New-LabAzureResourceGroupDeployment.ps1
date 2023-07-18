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
            NicApi            = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'networkInterfaces').ApiVersions[0] # 2022-01-01
            DiskApi           = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'disks').ApiVersions[0] # 2022-01-01
            LoadBalancerApi   = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'loadBalancers').ApiVersions[0] # 2022-01-01
            PublicIpApi       = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'publicIpAddresses').ApiVersions[0] # 2022-01-01
            VirtualNetworkApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualNetworks').ApiVersions[0] # 2022-01-01
            NsgApi            = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'networkSecurityGroups').ApiVersions[0] # 2022-01-01
            VmApi             = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualMachines').ApiVersions[1] # 2022-03-01
        }
        if (-not $lab.AzureSettings.IsAzureStack)
        {
            $provHash.BastionHostApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Network').ResourceTypes | Where-Object ResourceTypeName -eq 'bastionHosts').ApiVersions[0] # 2022-01-01
        }
        if ($lab.AzureSettings.IsAzureStack)
        {
            $provHash.VmApi = (($providers | Where-Object ProviderNamespace -eq 'Microsoft.Compute').ResourceTypes | Where-Object ResourceTypeName -eq 'virtualMachines').ApiVersions[0]
        }
        $provHash
    }
    elseif ($Lab.AzureSettings.IsAzureStack)
    {
        @{
            NicApi            = '2018-11-01'
            DiskApi           = '2018-11-01'
            LoadBalancerApi   = '2018-11-01'
            PublicIpApi       = '2018-11-01'
            VirtualNetworkApi = '2018-11-01'
            NsgApi            = '2018-11-01'
            VmApi             = '2020-06-01'
        }
    }
    else
    {
        @{
            NicApi            = '2022-01-01'
            DiskApi           = '2022-01-01'
            LoadBalancerApi   = '2022-01-01'
            PublicIpApi       = '2022-01-01'
            VirtualNetworkApi = '2022-01-01'
            BastionHostApi    = '2022-01-01'
            NsgApi            = '2022-01-01'
            VmApi             = '2022-03-01'
        }
    }
    
    #region Network Security Group
    Write-ScreenInfo -Type Verbose -Message 'Adding network security group to template, enabling traffic to ports 3389,5985,5986,22 for VMs behind load balancer'
    [string[]]$allowedIps = (Get-LabVm -IncludeLinux).AzureProperties["LoadBalancerAllowedIp"] | Foreach-Object { $_ -split '\s*[,;]\s*' } | Where-Object { -not [string]::IsNullOrWhitespace($_) }
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

            if (($Lab.VirtualNetworks | Where-Object ResourceName -eq $nic.VirtualSwitch).DnsServers)
            {
                $nicTemplate.properties.dnsSettings = @{
                    dnsServers = [string[]](($Lab.VirtualNetworks | Where-Object ResourceName -eq $nic.VirtualSwitch).DnsServers.AddressAsString)
                }
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

        if (($Machine.VmGeneration -eq 2 -and $vmSize.Gen2Supported) -or ($vmSize.Gen2Supported -and -not $vmSize.Gen1Supported))
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
            throw "No valid VM size found for '$Machine'. For a list of available role sizes, use the command 'Get-LabAzureAvailableRoleSize -LocationName $($lab.AzureSettings.DefaultLocation.Location)'"
        }

        Write-ScreenInfo -Type Verbose -Message "Adding $Machine with size $vmSize, publisher $($imageRef.publisher), offer $($imageRef.offer), sku $($imageRef.sku)!"

        $machNet = Get-LabVirtualNetworkDefinition -Name $machine.Network[0]
        $machTemplate = @{
            name       = $machine.ResourceName
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            dependsOn  = @()
            properties = @{
                storageProfile  = @{
                    osDisk         = @{
                        createOption = "FromImage"
                        osType       = $Machine.OperatingSystemType.ToString()
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
                    adminUsername            = if ($machine.OperatingSystemType -eq 'Linux') { 'automatedlab' } else { ($machine.GetLocalCredential($true).UserName -split '\\')[-1] }
                }
                hardwareProfile = @{
                    vmSize = $vmSize.Name
                }
            }
            type       = "Microsoft.Compute/virtualMachines"
            apiVersion = $apiVersions['VmApi']
            location   = "[resourceGroup().location]"
        }

        if ($machine.OperatingSystem.OperatingSystemName -like 'Kali*')
        {
            # This is a marketplace offer, so we have to do redundant stuff for no good reason
            $machTemplate.plan = @{
                name      = $imageRef.sku # Otherwise known as sku
                product   = $imageRef.offer # Otherwise known as offer
                publisher = $imageRef.publisher # publisher
            }
        }

        if ($machine.OperatingSystemType -eq 'Windows')
        {
            $machTemplate.properties.osProfile.windowsConfiguration = @{
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

        if ($machine.OperatingSystemType -eq 'Linux')
        {
            if ($machine.SshPublicKey)
            {
                $machTemplate.properties.osProfile.linuxConfiguration = @{
                    disablePasswordAuthentication = $true
                    enableVMAgentPlatformUpdates  = $true
                    provisionVMAgent              = $true
                    ssh                           = @{
                        publicKeys = [hashtable[]]@(@{
                                keyData = $machine.SshPublicKey
                                path    = "/home/automatedlab/.ssh/authorized_keys"
                            }
                        )
                    }
                }
            }
        }
        
        if ($machine.AzureProperties['EnableSecureBoot'] -and -not $lab.AzureSettings.IsAzureStack) # Available only in public regions
        {            
            $machTemplate.properties.securityProfile = @{
                securityType = 'TrustedLaunch'
                uefiSettings = @{
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
