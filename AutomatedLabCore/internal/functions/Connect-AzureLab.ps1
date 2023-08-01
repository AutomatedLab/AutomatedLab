function Connect-AzureLab
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceLab,
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationLab
    )

    Write-LogFunctionEntry
    Import-Lab $SourceLab -NoValidation
    $lab = Get-Lab
    $sourceResourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $sourceLocation = Get-LabAzureDefaultLocation
    $sourceVnet = Initialize-GatewayNetwork -Lab $lab

    Import-Lab $DestinationLab -NoValidation
    $lab = Get-Lab
    $destinationResourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $destinationLocation = Get-LabAzureDefaultLocation
    $destinationVnet = Initialize-GatewayNetwork -Lab $lab

    $sourcePublicIpParameters = @{
        ResourceGroupName = $sourceResourceGroupName
        Location          = $sourceLocation
        Name              = 's2sip'
        AllocationMethod  = 'Dynamic'
        IpAddressVersion  = 'IPv4'
        DomainNameLabel   = "$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        Force             = $true
    }

    $destinationPublicIpParameters = @{
        ResourceGroupName = $destinationResourceGroupName
        Location          = $destinationLocation
        Name              = 's2sip'
        AllocationMethod  = 'Dynamic'
        IpAddressVersion  = 'IPv4'
        DomainNameLabel   = "$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        Force             = $true
    }

    $sourceGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $sourceVnet -ErrorAction SilentlyContinue
    $sourcePublicIp = New-AzPublicIpAddress @sourcePublicIpParameters
    $sourceGatewayIpConfiguration = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig -SubnetId $sourceGatewaySubnet.Id -PublicIpAddressId $sourcePublicIp.Id

    $sourceGatewayParameters = @{
        ResourceGroupName = $sourceResourceGroupName
        Location          = $sourceLocation
        Name              = 's2sgw'
        GatewayType       = 'Vpn'
        VpnType           = 'RouteBased'
        GatewaySku        = 'VpnGw1'
        IpConfigurations  = $sourceGatewayIpConfiguration
    }

    $destinationGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $destinationVnet -ErrorAction SilentlyContinue
    $destinationPublicIp = New-AzPublicIpAddress @destinationPublicIpParameters
    $destinationGatewayIpConfiguration = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig -SubnetId $destinationGatewaySubnet.Id -PublicIpAddressId $destinationPublicIp.Id

    $destinationGatewayParameters = @{
        ResourceGroupName = $destinationResourceGroupName
        Location          = $destinationLocation
        Name              = 's2sgw'
        GatewayType       = 'Vpn'
        VpnType           = 'RouteBased'
        GatewaySku        = 'VpnGw1'
        IpConfigurations  = $destinationGatewayIpConfiguration
    }


    # Gateway creation
    $sourceGateway = Get-AzVirtualNetworkGateway -Name s2sgw -ResourceGroupName $sourceResourceGroupName -ErrorAction SilentlyContinue
    if (-not $sourceGateway)
    {
        Write-ScreenInfo -TaskStart -Message 'Creating Azure Virtual Network Gateway - this will take some time.'
        $sourceGateway = New-AzVirtualNetworkGateway @sourceGatewayParameters
        Write-ScreenInfo -TaskEnd -Message 'Source gateway created'
    }

    $destinationGateway = Get-AzVirtualNetworkGateway -Name s2sgw -ResourceGroupName $destinationResourceGroupName -ErrorAction SilentlyContinue
    if (-not $destinationGateway)
    {
        Write-ScreenInfo -TaskStart -Message 'Creating Azure Virtual Network Gateway - this will take some time.'
        $destinationGateway = New-AzVirtualNetworkGateway @destinationGatewayParameters
        Write-ScreenInfo -TaskEnd -Message 'Destination gateway created'
    }

    $sourceConnection = @{
        ResourceGroupName      = $sourceResourceGroupName
        Location               = $sourceLocation
        Name                   = 's2sconnection'
        ConnectionType         = 'Vnet2Vnet'
        SharedKey              = 'Somepass1'
        Force                  = $true
        VirtualNetworkGateway1 = $sourceGateway
        VirtualNetworkGateway2 = $destinationGateway
    }

    $destinationConnection = @{
        ResourceGroupName      = $destinationResourceGroupName
        Location               = $destinationLocation
        Name                   = 's2sconnection'
        ConnectionType         = 'Vnet2Vnet'
        SharedKey              = 'Somepass1'
        Force                  = $true
        VirtualNetworkGateway1 = $destinationGateway
        VirtualNetworkGateway2 = $sourceGateway
    }

    [void] (New-AzVirtualNetworkGatewayConnection @sourceConnection)
    [void] (New-AzVirtualNetworkGatewayConnection @destinationConnection)

    Write-PSFMessage -Message 'Connection created - please allow some time for initial connection.'

    Set-VpnDnsForwarders -SourceLab $SourceLab -DestinationLab $DestinationLab

    Write-LogFunctionExit
}
