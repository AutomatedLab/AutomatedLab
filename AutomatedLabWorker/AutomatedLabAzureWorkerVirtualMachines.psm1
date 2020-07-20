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
    
    #region Network Security Group
    Write-ScreenInfo -Type Verbose -Message 'Adding network security group to template, enabling traffic to ports 3389,5985,5986 for VMs behind load balancer'
    [string[]]$allowedIps = (Get-LabVm).AzureProperties["LoadBalancerAllowedIp"] | Foreach-Object {$_ -split '\s*[,;]\s*'} | Where-Object {-not [string]::IsNullOrWhitespace($_)}
    $nsg = @{
        type       = "Microsoft.Network/networkSecurityGroups"
        apiVersion = "[providers('Microsoft.Network','networkSecurityGroups').apiVersions[0]]"
        name       = "$($Lab.Name)nsg"
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
            )
        }
    }

    if ($allowedIps)
    {
        $nsg.properties.securityrules | Where-Object {$_.properties.direction -eq 'Inbound'} | Foreach-object {$_.properties.sourceAddressPrefixes = $allowedIps}
    }
    $template.resources += $nsg
    #endregion

    #region Wait for availability of Bastion
    if ($Lab.AzureSettings.AllowBastionHost)
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

    foreach ($network in $Lab.VirtualNetworks)
    {
        #region VNet
        Write-ScreenInfo -Type Verbose -Message ('Adding vnet {0} ({1}) to template' -f $network.ResourceName, $network.AddressSpace)
        $vNet = @{
            type       = "Microsoft.Network/virtualNetworks"
            apiVersion = "[providers('Microsoft.Network','virtualNetworks').apiVersions[0]]"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            dependsOn  = @(
                "[resourceId('Microsoft.Network/networkSecurityGroups', '$($Lab.Name)nsg')]"
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

        if ($network.DnsServers)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding DNS Servers to VNet template: {0}' -f $network.DnsServers)
            $vNet.properties.dhcpOptions.dnsServers = [string[]]($network.DnsServers.AddressAsString)
        }

        if (-not $network.Subnets)
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding default subnet ({0}) to VNet' -f $network.AddressSpace)
            $vnet.properties.subnets += @{
                name                 = "default"
                properties           = @{
                    addressPrefix = $network.AddressSpace.ToString()
                    networkSecurityGroup = @{
                        id = "[resourceId('Microsoft.Network/networkSecurityGroups', '$($Lab.Name)nsg')]"
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
                    addressPrefix = $subnet.AddressSpace.ToString()
                    networkSecurityGroup = @{
                        id = "[resourceId('Microsoft.Network/networkSecurityGroups', '$($Lab.Name)nsg')]"
                    }
                }
            }
        }

        if ($Lab.AzureSettings.AllowBastionHost)
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
                    name = 'AzureBastionSubnet'
                    properties = @{
                        addressPrefix = $bastionNet.AddressSpace.ToString()
                        networkSecurityGroup = @{
                            id = "[resourceId('Microsoft.Network/networkSecurityGroups', '$($Lab.Name)nsg')]"
                        }
                    }
                }
            }

            $dnsLabel = "azbastion$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
            Write-ScreenInfo -Type Verbose -Message ('Adding Azure bastion public static IP with DNS label {0} to template' -f $dnsLabel)
            $template.resources +=
            @{
                apiVersion = "[providers('Microsoft.Network','publicIPAddresses').apiVersions[0]]"
                tags       = @{ 
                        AutomatedLab = $Lab.Name
                        CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
                type       = "Microsoft.Network/publicIPAddresses"
                name       = "$($Lab.Name)$($network.ResourceName)bastionip"
                location   = "[resourceGroup().location]"
                properties = @{
                    publicIPAllocationMethod = "static"
                    dnsSettings              = @{
                        domainNameLabel = $dnsLabel
                    }
                }
                sku        = @{
                    name = 'Standard'
                }
            }

            $template.resources += @{
                apiVersion = "[providers('Microsoft.Network','bastionHosts').apiVersions[0]]"
                type       = "Microsoft.Network/bastionHosts"
                name       = "$($Lab.Name)$($network.ResourceName)bastion"
                tags       = @{ 
                    AutomatedLab = $Lab.Name
                    CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
                location   = "[resourceGroup().location]"
                dependsOn  = @(
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($network.ResourceName)')]"
                    "[resourceId('Microsoft.Network/publicIPAddresses', '$($Lab.Name)$($network.ResourceName)bastionip')]"
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
                                    id = "[resourceId('Microsoft.Network/publicIPAddresses', '$($Lab.Name)$($network.ResourceName)bastionip')]"
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
                apiVersion = "[providers('Microsoft.Network', 'virtualNetworks').apiVersions[0]]"
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
        $dnsLabel = "$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"

        if ($network.AzureDnsLabel)
        {
            $dnsLabel = $network.AzureDnsLabel
        }

        Write-ScreenInfo -Type Verbose -Message ('Adding public static IP with DNS label {0} to template' -f $dnsLabel)
        $template.resources +=
        @{
            apiVersion = "[providers('Microsoft.Network','publicIPAddresses').apiVersions[0]]"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            type       = "Microsoft.Network/publicIPAddresses"
            name       = "$($Lab.Name)$($network.ResourceName)lbfrontendip"
            location   = "[resourceGroup().location]"
            properties = @{
                publicIPAllocationMethod = "static"
                dnsSettings              = @{
                    domainNameLabel = $dnsLabel
                }
            }
            sku        = @{
                name = 'Standard'
            }
        }
        #endregion

        #region Load balancer
        Write-ScreenInfo -Type Verbose -Message ('Adding load balancer to template')
        $loadBalancer = @{
            type       = "Microsoft.Network/loadBalancers"
            tags       = @{ 
                AutomatedLab = $Lab.Name
                CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }
            apiVersion = "[providers('Microsoft.Network','loadBalancers').apiVersions[0]]"
            name       = "$($Lab.Name)$($network.ResourceName)loadbalancer"
            location   = "[resourceGroup().location]"
            sku        = @{
                name = "Standard"
            }
            dependsOn  = @(
                "[resourceId('Microsoft.Network/publicIPAddresses', '$($Lab.Name)$($network.ResourceName)lbfrontendip')]"
            )
            properties = @{
                frontendIPConfigurations = @(
                    @{
                        name       = "$($Lab.Name)$($network.ResourceName)lbfrontendconfig"
                        properties = @{
                            publicIPAddress = @{
                                id = "[resourceId('Microsoft.Network/publicIPAddresses', '$($Lab.Name)$($network.ResourceName)lbfrontendip')]"
                            }
                        }
                    }
                )
                backendAddressPools      = @(
                    @{
                        name = "$($Lab.Name)$($network.ResourceName)backendpoolconfig"
                    }
                )
                outboundRules = @(
                    @{
                        name = "InternetAccess"
                        properties = @{
                            allocatedOutboundPorts = 0 # In order to use automatic allocation
                            frontendIPConfigurations = @(
                                @{
                                    id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '$($Lab.Name)$($network.ResourceName)loadbalancer', '$($Lab.Name)$($network.ResourceName)lbfrontendconfig')]"
                                }
                            )
                            backendAddressPool = @{
                                id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($network.ResourceName)loadbalancer'), '/backendAddressPools/$($Lab.Name)$($network.ResourceName)backendpoolconfig')]"
                            }
                            protocol = "All"
                            enableTcpReset = $true
                            idleTimeoutInMinutes = 4
                        }
                    }
                )
            }
        }

        $rules = foreach ($machine in ($Lab.Machines | Where-Object -FilterScript {$_.Network -EQ $network.Name -and -not $_.SkipDeployment}))
        {
            Write-ScreenInfo -Type Verbose -Message ('Adding inbound NAT rules for {0}: {1}:3389, {2}:5985, {3}:5986' -f $machine, $machine.LoadBalancerRdpPort, $machine.LoadBalancerWinRmHttpPort, $machine.LoadBalancerWinrmHttpsPort)
            @{
                name       = "$($machine.ResourceName.ToLower())rdpin"
                properties = @{
                    frontendIPConfiguration = @{
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '$($Lab.Name)$($network.ResourceName)loadbalancer', '$($Lab.Name)$($network.ResourceName)lbfrontendconfig')]"
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
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '$($Lab.Name)$($network.ResourceName)loadbalancer', '$($Lab.Name)$($network.ResourceName)lbfrontendconfig')]"
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
                        id = "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '$($Lab.Name)$($network.ResourceName)loadbalancer', '$($Lab.Name)$($network.ResourceName)lbfrontendconfig')]"
                    }
                    frontendPort            = $machine.LoadBalancerWinrmHttpsPort
                    backendPort             = 5986
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
            apiVersion = "[providers('Microsoft.Compute','availabilitySets').apiVersions[0]]"
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
            apiVersion = "[providers('Microsoft.Compute','disks').apiVersions[0]]"
            name       = $disk.Name
            location   = "[resourceGroup().location]"
            sku        = @{
                name = if ($vm.AzureProperties.ContainsKey('StorageSku'))
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

    foreach ($machine in $Lab.Machines.Where({-not $_.SkipDeployment}))
    {
        $niccount = 0
        foreach ($nic in $machine.NetworkAdapters)
        {
            Write-ScreenInfo -Type Verbose -Message ('Creating NIC {0}' -f $nic.InterfaceName)
            $subnetName = 'default'
            if (($nic.VirtualSwitch.Subnets | Where-Object -Property Name -ne AzureBastionSubnet | Select-Object -First 1).Name)
            {
                $subnetName = ($nic.VirtualSwitch.Subnets | Where-Object -Property Name -ne AzureBastionSubnet | Select-Object -First 1).Name
            }
             
            $nicTemplate = @{
                dependsOn  = @(
                    "[resourceId('Microsoft.Network/virtualNetworks', '$($nic.VirtualSwitch.ResourceName)')]"
                    "[resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($nic.VirtualSwitch.ResourceName)loadbalancer')]"
                )
                properties = @{
                    enableAcceleratedNetworking = $false
                    ipConfigurations            = @(
                        @{
                            properties = @{
                                subnet                          = @{
                                    id = "[resourceId('Microsoft.Network/virtualNetworks/subnets', '$($nic.VirtualSwitch.ResourceName)', '$subnetName')]"
                                }
                                primary                         = $true
                                privateIPAllocationMethod       = "Static"
                                privateIPAddress                = $nic.Ipv4Address[0].IpAddress.AddressAsString
                                privateIPAddressVersion         = "IPv4"                                
                                loadBalancerBackendAddressPools = @(
                                    @{
                                        id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($nic.VirtualSwitch.ResourceName)loadbalancer'), '/backendAddressPools/$($Lab.Name)$($nic.VirtualSwitch.ResourceName)backendpoolconfig')]"
                                    }
                                )
                                loadBalancerInboundNatRules     = @(
                                    @{
                                        id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($nic.VirtualSwitch.ResourceName)loadbalancer'),'/inboundNatRules/$($machine.ResourceName.ToLower())rdpin')]"
                                    }
                                    @{
                                        id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($nic.VirtualSwitch.ResourceName)loadbalancer'),'/inboundNatRules/$($machine.ResourceName.ToLower())winrmin')]"
                                    }
                                    @{
                                        id = "[concat(resourceId('Microsoft.Network/loadBalancers', '$($Lab.Name)$($nic.VirtualSwitch.ResourceName)loadbalancer'),'/inboundNatRules/$($machine.ResourceName.ToLower())winrmhttpsin')]"
                                    }
                                )
                            }
                            name       = "ipconfig1"
                        }
                    )
                    enableIPForwarding          = $false
                }
                name       = "$($machine.ResourceName)nic$($niccount)"
                apiVersion = "[providers('Microsoft.Network','networkInterfaces').apiVersions[0]]"
                type       = "Microsoft.Network/networkInterfaces"
                location   = "[resourceGroup().location]"
                tags       = @{ 
                    AutomatedLab = $Lab.Name
                    CreationTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
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
                    }
                    imageReference = Get-LWAzureSku -Machine $machine
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
                    vmSize = (Get-LWAzureVmSize -Machine $Machine).Name
                }
            }
            type       = "Microsoft.Compute/virtualMachines"
            apiVersion = "[providers('Microsoft.Compute','virtualMachines').apiVersions[0]]"
            location   = "[resourceGroup().location]"
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
    $deployment = if ($Wait.IsPresent)
    {
        New-AzResourceGroupDeployment @rgDeplParam
    }
    else
    {
        New-AzResourceGroupDeployment @rgDeplParam -AsJob # Splatting AsJob did not work
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

    if ($machine.AzureProperties.RoleSize)
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
        offer = $offerName
        publisher = $publisherName
        sku = $skusName
        version = 'latest'
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
    foreach ($adapter in ($Machine.NetworkAdapters | Where-Object {$_.Ipv4Address.IPAddress.ToString() -ne $defaultIPv4Address}))
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

            [int]
            $DiskCount,

            [string]
            $LabSourcesPath,

            [string]
            $StorageAccountName,

            [string]
            $StorageAccountKey,

            [string[]]
            $DnsServers
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

        #Set Power Scheme to High Performance
        powercfg.exe -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

        #Create a scheduled tasks that maps the Azure lab sources drive during each logon
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

        if (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue)
        {
            $trigger = New-ScheduledTaskTrigger -Once -At '0:00:00'
            $action = New-ScheduledTaskAction -Execute (Join-Path $PSHome 'powershell.exe') -Argument '-File C:\AL\AzureLabSources.ps1'
            $principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\System' -RunLevel Highest
            $task = New-ScheduledTask -Trigger $trigger -Action $action -Principal $principal
            $task = $task | Register-ScheduledTask -TaskName ALLabSourcesCmdKey -Force
            $task | Start-ScheduledTask
        }
        else
        {
            SCHTASKS /Create /SC ONCE /ST 00:00 /TN ALLabSourcesCmdKey /TR "powershell.exe -File C:\AL\AzureLabSources.ps1" /RU "NT AUTHORITY\SYSTEM"
        }

        #set the time zone
        Set-TimeZone -Name $TimeZoneId

        reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' /v ALLabSourcesCmdKey /d 'powershell.exe -File C:\AL\AzureLabSources.ps1' /t REG_SZ /f
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
            $idx = (Get-NetIPInterface | Where-object {$_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -like "*Ethernet*"}).ifIndex
            Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $DnsServers
        }

        Write-Verbose -Message "Disk count for $computerName`: $DiskCount"
        if ($DiskCount -gt 0)
        {
            $diskpartCmd = 'LIST DISK'

            $disks = $diskpartCmd | diskpart.exe

            foreach ($line in $disks)
            {
                if ($line -match 'Disk (?<DiskNumber>\d) \s+(Online|Offline)\s+(?<Size>\d+) GB\s+(?<Free>\d+) (B|GB)')
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

    $initScriptFile = New-TemporaryFile
    $initScript.ToString() | Set-Content -Path $initScriptFile -Force

    # Configure AutoShutdown
    if ($lab.AzureSettings.AutoShutdownTime)
    {
        $time = $lab.AzureSettings.AutoShutdownTime
        $tz = if (-not $lab.AzureSettings.AutoShutdownTimeZone) {Get-TimeZone} else {Get-TimeZone -Id $lab.AzureSettings.AutoShutdownTimeZone}
        Write-ScreenInfo -Message "Configuring auto-shutdown of all VMs daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName (Get-LabVm | Where-Object Name -notin $machineSpecific.Name) -Time $time -TimeZone $tz -Wait
    }

    $machineSpecific = Get-LabVm -SkipConnectionInfo | Where-Object {
        $_.AzureProperties.ContainsKey('AutoShutdownTime')
    }

    foreach ($machine in $machineSpecific)
    {
        $time = $machine.AzureProperties.AutoShutdownTime
        $tz = if (-not $machine.AzureProperties.AutoShutdownTimezoneId) {Get-TimeZone} else {Get-TimeZone -Id $machine.AzureProperties.AutoShutdownTimezoneId}
        Write-ScreenInfo -Message "Configure shutdown of $machine daily at $($time) in timezone $($tz.Id)"
        Enable-LWAzureAutoShutdown -ComputerName $machine -Time $time -TimeZone $tz -Wait
    }

    Write-ScreenInfo -Message 'Configuring localization and additional disks' -TaskStart -NoNewLine
    $labsourcesStorage = Get-LabAzureLabSourcesStorage
    $jobs = foreach ($m in $Machine)
    {
        [string[]]$DnsServers = ($m.NetworkAdapters | Where-Object {$_.VirtualSwitch.Name -eq $Lab.Name}).Ipv4DnsServers.AddressAsString
        $scriptParam = @{
            UserLocale         = $m.UserLocale
            TimeZoneId         = $m.TimeZone
            DiskCount          = $m.Disks.Count
            LabSourcesPath     = $labsourcesStorage.Path
            StorageAccountName = $labsourcesStorage.StorageAccountName
            StorageAccountKey  = $labsourcesStorage.StorageAccountKey
            DnsServers         = $DnsServers
        }

        if ($DNSServers.Count -eq 0) {$scriptParam.Remove('DnsServers')}
        Invoke-AzVMRunCommand -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName -VMName $m.ResourceName -ScriptPath $initScriptFile -Parameter $scriptParam -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob
    }

    Wait-LWLabJob -Job $jobs -ProgressIndicator 5 -Timeout 30 -NoDisplay
    Copy-LabFileItem -Path (Get-ChildItem -Path "$((Get-Module -Name AutomatedLab)[0].ModuleBase)\Tools\HyperV\*") -DestinationFolderPath /AL -ComputerName $Machine -UseAzureLabSourcesOnAzureVm $false
    Copy-LabALCommon -ComputerName $Machine
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
        [string]$ComputerName,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $Lab = Get-Lab

    if ($AsJob)
    {
        $job = Start-Job -ScriptBlock {
            param (
                [Parameter(Mandatory)]
                [hashtable]$ComputerName
            )

            $resourceGroup = ((Get-LabVM -ComputerName $ComputerName).AzureConnectionInfo.ResourceGroupName)

            $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $ComputerName

            $vm | Remove-AzVM -Force
        } -ArgumentList $ComputerName

        if ($PassThru)
        {
            $job
        }
    }
    else
    {
        $resourceGroup = ((Get-LabVM -ComputerName $ComputerName).AzureConnectionInfo.ResourceGroupName)
        $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $ComputerName

        $result = $vm | Remove-AzVM -Force
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

    $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $azureVms)
    {
        Start-Sleep -Seconds 2
        $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $azureVms)
        {
            throw 'Get-AzVM did not return anything, stopping lab deployment. Code will be added to handle this error soon'
        }
    }

    $stoppedAzureVms = $azureVms | Where-Object { $_.PowerState -ne 'VM running' -and $_.Name -in $machines.ResourceName}

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
    $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $azureVms)
    {
        Start-Sleep -Seconds 2
        $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $azureVms)
        {
            throw 'Get-AzVM did not return anything, stopping lab deployment. Code will be added to handle this error soon'
        }
    }

    $azureVms = $azureVms | Where-Object { $_.Name -in $machines.ResourceName}

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
        $linux, $windows = $machines.Where( {$_.OperatingSystemType -eq 'Linux'}, 'Split')

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
        $jobs = foreach ($name in $machines.ResourceName)
        {
            $vm = $azureVms | Where-Object Name -eq $name
            $vm | Stop-AzVM -Force -StayProvisioned:$StayProvisioned -AsJob
        }

        Wait-LWLabJob -Job $jobs -NoDisplay -ProgressIndicator $ProgressIndicator
        $failedJobs = $jobs | Where-Object {$_.State -eq 'Failed'}
        if ($failedJobs)
        {
            $jobNames = ($failedJobs | ForEach-Object {
                    if ($_.Name.StartsWith("StopAzureVm_"))
                    {
                        ($_.Name -split "_")[1]
                    }
                    elseif ($_.Name  -match "Long Running Operation for 'Stop-AzVM' on resource '(?<MachineName>[\w-]+)'")
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
    $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $azureVms)
    {
        Start-Sleep -Seconds 2
        $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $azureVms)
        {
            throw 'Get-AzVM did not return anything, stopping lab deployment. Code will be added to handle this error soon'
        }
    }

    $resourceGroups = (Get-LabVM).AzureConnectionInfo.ResourceGroupName | Select-Object -Unique
    $azureVms = $azureVms | Where-Object { $_.Name -in $ComputerName -and $_.ResourceGroupName -in $resourceGroups }

    $vmTable = @{ }
    Get-LabVm -IncludeLinux | Where-Object FriendlyName -in $ComputerName | ForEach-Object {$vmTable[$_.FriendlyName] = $_.Name}

    foreach ($azureVm in $azureVms)
    {
        $vmName = if ($vmTable[$azureVm.Name]) {$vmTable[$azureVm.Name]} else {$azureVm.Name}
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

        $net = $lab.VirtualNetworks.Where({$_.Name -eq $name.Network[0]})
        $ip = Get-AzPublicIpAddress -Name "$($resourceGroupName)$($net.ResourceName)lbfrontendip" -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

        $result = [AutomatedLab.Azure.AzureConnectionInfo] @{
            ComputerName      = $name.Name
            DnsName           = $ip.DnsSettings.Fqdn
            HttpsName         = $ip.DnsSettings.Fqdn
            VIP               = $ip.IpAddress
            Port              = $name.LoadBalancerWinrmHttpPort
            HttpsPort         = $name.LoadBalancerWinrmHttpsPort
            RdpPort           = $name.LoadBalancerRdpPort
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
        Write-PSFMessage "ResourceGroupName = $($azureVM.ResourceGroupName)"

        $result
    }

    Write-LogFunctionExit -ReturnValue $result
}
#endregion Get-LWAzureVMConnectionInfo

#region Enable-LWAzureVMRemoting
function Enable-LWAzureVMRemoting
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not enabling CredSSP a third time on Linux")]
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
        Invoke-AzVMRunCommand -ResourceGroupName $rgName -VMName $m.ResourceName -ScriptPath $tempFileName -CommandId 'RunPowerShellScript' -ErrorAction Stop -AsJob
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

    Test-LabHostConnected -Throw -Quiet

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $labSourcesStorageAccount = Get-LabAzureLabSourcesStorage -ErrorAction SilentlyContinue

    if ($Session.Runspace.ConnectionInfo.AuthenticationMechanism -notin 'CredSsp','Negotiate' -or -not $labSourcesStorageAccount)
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant, used in Invoke-LabCommand")]
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
    # ISO file should already exist on Azure storage share, as it was initially retrieved from there as well.
    $azureIsoPath = $IsoPath -replace '/', '\' -replace 'https:'

    Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName.Name -join ',')" -ComputerName $ComputerName -ScriptBlock {

        if (-not (Test-Path -Path $azureIsoPath))
        {
            throw "'$azureIsoPath' is not accessible."
        }

        $drive = Mount-DiskImage -ImagePath $azureIsoPath -StorageType ISO -PassThru | Get-Volume
        $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
        $drive | Select-Object -Property *

    } -ArgumentList $azureIsoPath -Variable (Get-Variable -Name azureIsoPath) -PassThru:$PassThru
}
#endregion

#region Dismount-LWAzureIsoImage
function Dismount-LWAzureIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant, used in Invoke-LabCommand")]
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

    }
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
    $ComputerName.ForEach( {$machineStatus[$_] = @{ Stage1 = $null; Stage2 = $null; Stage3 = $null } })

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

    $null = $machineStatus.Values.Stage1.Job | Wait-Job

    $failedStage1 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript {$_.Value.Stage1.Job.State -eq 'Failed'}).Name
    if ($failedStage1) { Write-ScreenInfo -Type Error -Message "The following machines failed to create a new disk from the snapshot: $($failedStage1 -join ',')"}

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript {$_.Value.Stage1.Job.State -eq 'Completed'}).Name

    foreach ($machine in $ComputerName)
    {
        $vm = $vms | Where-Object Name -eq $machine
        $newDisk = $machineStatus[$machine].Stage1.Job | Receive-Job -Keep
        $null = Set-AzVMOSDisk -VM $vm -ManagedDiskId $newDisk.Id -Name $newDisk.Name
        $machineStatus[$machine].Stage2 = @{
            Job = Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm -AsJob
        }
    }

    $null = $machineStatus.Values.Stage2.Job | Wait-Job

    $failedStage2 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript {$_.Value.Stage2.Job.State -eq 'Failed'}).Name
    if ($failedStage2) { Write-ScreenInfo -Type Error -Message "The following machines failed to update with the new OS disk created from a snapshot: $($failedStage2 -join ',')"}

    $ComputerName = $($machineStatus.GetEnumerator() | Where-Object -FilterScript {$_.Value.Stage2.Job.State -eq 'Completed'}).Name

    foreach ($machine in $ComputerName)
    {
        $disk = $machineStatus[$machine].Stage1.OldDisk
        $machineStatus[$machine].Stage3 = @{
            Job = Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $disk -Confirm:$false -Force -AsJob
        }
    }

    $null = $machineStatus.Values.Stage3.Job | Wait-Job

    $failedStage3 = $($machineStatus.GetEnumerator() | Where-Object -FilterScript {$_.Value.Stage3.Job.State -eq 'Failed'}).Name
    if ($failedStage3)
    {
        $failedDisks = $failedStage3.ForEach( {$machineStatus[$_].Stage1.OldDisk})
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
    $machineStatus.Values.Values.Job | Remove-Job

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
        $snapshotsToRemove = $ComputerName.Foreach( {'{0}_{1}' -f $_, $SnapshotName})
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
        $snapshots = $snapshots | Where-Object {($_.Name -split '_')[1] -eq $SnapshotName}
    }

    if ($ComputerName)
    {
        $snapshots = $snapshots | Where-Object {($_.Name -split '_')[0] -in $ComputerName}
    }

    $snapshots.ForEach({
        [AutomatedLab.Snapshot]::new(($_.Name -split '_')[1], ($_.Name -split '_')[0], $_.TimeCreated)
    })
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
                Time = New-TimeSpan -Hours $hour -Minutes $minute
                TimeZone = Get-TimeZone -Id $schedule.timeZoneId
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

        [TimeZoneInfo]
        $TimeZone = (Get-TimeZone),

        [switch]
        $Wait
    )

    $lab = Get-Lab -ErrorAction Stop
    $labVms = Get-AzVm -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName | Where-Object Name -in $ComputerName
    $resourceIdString = '{0}/providers/microsoft.devtestlab/schedules/shutdown-computevm-' -f $lab.AzureSettings.DefaultResourceGroup.ResourceId

    $jobs = foreach ($vm in $labVms)
    {
        $properties = @{
            status = 'Enabled'
            taskType = 'ComputeVmShutdownTask'
            dailyRecurrence = @{time = $Time.ToString('hhmm') }
            timeZoneId = $TimeZone.Id
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
    $labVms = Get-AzVm -ResourceGroupName $lab.AzureSettings.DefaultResourceGroup.ResourceGroupName | Where-Object Name -in $ComputerName
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
