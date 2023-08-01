function Initialize-GatewayNetwork
{
    param
    (
        [Parameter(Mandatory = $true)]
        [AutomatedLab.Lab]
        $Lab
    )

    Write-LogFunctionEntry
    Write-PSFMessage -Message ('Creating gateway subnet for lab {0}' -f $Lab.Name)

    $targetNetwork = $Lab.VirtualNetworks | Select-Object -First 1
    $sourceMask = $targetNetwork.AddressSpace.Cidr
    $sourceMaskIp = $targetNetwork.AddressSpace.NetMask
    $superNetMask = $sourceMask - 1
    $superNetIp = $targetNetwork.AddressSpace.IpAddress.AddressAsString

    $gatewayNetworkAddressFound = $false
    $incrementedIp = $targetNetwork.AddressSpace.IPAddress.Increment()
    $decrementedIp = $targetNetwork.AddressSpace.IPAddress.Decrement()
    $isDecrementing = $false

    while (-not $gatewayNetworkAddressFound)
    {
        if (-not $isDecrementing)
        {
            $incrementedIp = $incrementedIp.Increment()
            $tempNetworkAdress = Get-NetworkAddress -IPAddress $incrementedIp.AddressAsString -SubnetMask $sourceMaskIp.AddressAsString

            if ($tempNetworkAdress -eq $targetNetwork.AddressSpace.Network.AddressAsString)
            {
                continue
            }

            $gatewayNetworkAddress = $tempNetworkAdress

            if ($gatewayNetworkAddress -in (Get-NetworkRange -IPAddress $targetnetwork.AddressSpace.Network.AddressAsString -SubnetMask $superNetMask))
            {
                $gatewayNetworkAddressFound = $true
            }
            else
            {
                $isDecrementing = $true
            }
        }

        $decrementedIp = $decrementedIp.Decrement()
        $tempNetworkAdress = Get-NetworkAddress -IPAddress $decrementedIp.AddressAsString -SubnetMask $sourceMaskIp.AddressAsString

        if ($tempNetworkAdress -eq $targetNetwork.AddressSpace.Network.AddressAsString)
        {
            continue
        }

        $gatewayNetworkAddress = $tempNetworkAdress

        if (([AutomatedLab.IPAddress]$gatewayNetworkAddress).Increment().AddressAsString -in (Get-NetworkRange -IPAddress $targetnetwork.AddressSpace.Network.AddressAsString -SubnetMask $superNetMask))
        {
            $gatewayNetworkAddressFound = $true
        }
    }

    Write-PSFMessage -Message ('Calculated supernet: {0}, extending Azure VNet and creating gateway subnet {1}' -f "$($superNetIp)/$($superNetMask)", "$($gatewayNetworkAddress)/$($sourceMask)")
    $vNet = Get-LWAzureNetworkSwitch -virtualNetwork $targetNetwork
    $vnet.AddressSpace.AddressPrefixes[0] = "$($superNetIp)/$($superNetMask)"
    $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet -ErrorAction SilentlyContinue

    if (-not $gatewaySubnet)
    {
        $vnet | Add-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -AddressPrefix "$($gatewayNetworkAddress)/$($sourceMask)"
        $vnet = $vnet | Set-AzVirtualNetwork -ErrorAction Stop
    }

    $vnet = (Get-LWAzureNetworkSwitch -VirtualNetwork $targetNetwork | Where-Object -Property ID)[0]
    Write-LogFunctionExit

    return $vnet
}
