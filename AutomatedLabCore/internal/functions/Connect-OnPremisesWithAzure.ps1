﻿function Connect-OnPremisesWithAzure
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceLab,
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationLab,
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AzureAddressSpaces,
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $OnPremAddressSpaces
    )

    Write-LogFunctionEntry
    Import-Lab $SourceLab -NoValidation
    $lab = Get-Lab
    $sourceResourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName
    $sourceLocation = Get-LabAzureDefaultLocation
    $sourceDcs = Get-LabVM -Role DC, RootDC, FirstChildDC

    $vnet = Initialize-GatewayNetwork -Lab $lab

    $labPublicIp = Get-PublicIpAddress

    if (-not $labPublicIp)
    {
        throw 'No public IP for hypervisor found. Make sure you are connected to the internet.'
    }

    Write-PSFMessage -Message "Found Hypervisor host public IP of $labPublicIp"

    $genericParameters = @{
        ResourceGroupName = $sourceResourceGroupName
        Location          = $sourceLocation
    }

    $publicIpParameters = $genericParameters.Clone()
    $publicIpParameters.Add('Name', 's2sip')
    $publicIpParameters.Add('AllocationMethod', 'Dynamic')
    $publicIpParameters.Add('IpAddressVersion', 'IPv4')
    $publicIpParameters.Add('DomainNameLabel', "$((1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')".ToLower())
    $publicIpParameters.Add('Force', $true)

    $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet -ErrorAction SilentlyContinue
    $gatewayPublicIp = New-AzPublicIpAddress @publicIpParameters
    $gatewayIpConfiguration = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig -SubnetId $gatewaySubnet.Id -PublicIpAddressId $gatewayPublicIp.Id

    $remoteGatewayParameters = $genericParameters.Clone()
    $remoteGatewayParameters.Add('Name', 's2sgw')
    $remoteGatewayParameters.Add('GatewayType', 'Vpn')
    $remoteGatewayParameters.Add('VpnType', 'RouteBased')
    $remoteGatewayParameters.Add('GatewaySku', 'VpnGw1')
    $remoteGatewayParameters.Add('IpConfigurations', $gatewayIpConfiguration)
    $remoteGatewayParameters.Add('Force', $true)

    $onPremGatewayParameters = $genericParameters.Clone()
    $onPremGatewayParameters.Add('Name', 'onpremgw')
    $onPremGatewayParameters.Add('GatewayIpAddress', $labPublicIp)
    $onPremGatewayParameters.Add('AddressPrefix', $onPremAddressSpaces)
    $onPremGatewayParameters.Add('Force', $true)

    # Gateway creation
    $gw = Get-AzVirtualNetworkGateway -Name s2sgw -ResourceGroupName $sourceResourceGroupName -ErrorAction SilentlyContinue
    if (-not $gw)
    {
        Write-ScreenInfo -TaskStart -Message 'Creating Azure Virtual Network Gateway - this will take some time.'
        $gw = New-AzVirtualNetworkGateway @remoteGatewayParameters
        Write-ScreenInfo -TaskEnd -Message 'Virtual Network Gateway created.'
    }

    $onPremisesGw = Get-AzLocalNetworkGateway -Name onpremgw -ResourceGroupName $sourceResourceGroupName -ErrorAction SilentlyContinue
    if (-not $onPremisesGw -or $onPremisesGw.GatewayIpAddress -ne $labPublicIp)
    {
        $onPremisesGw = New-AzLocalNetworkGateway @onPremGatewayParameters
    }

    # Connection creation
    $connectionParameters = $genericParameters.Clone()
    $connectionParameters.Add('Name', 's2sconnection')
    $connectionParameters.Add('ConnectionType', 'IPsec')
    $connectionParameters.Add('SharedKey', 'Somepass1')
    $connectionParameters.Add('EnableBgp', $false)
    $connectionParameters.Add('Force', $true)
    $connectionParameters.Add('VirtualNetworkGateway1', $gw)
    $connectionParameters.Add('LocalNetworkGateway2', $onPremisesGw)

    $conn = New-AzVirtualNetworkGatewayConnection @connectionParameters

    # Step 3: Import the HyperV lab and install a Router if not already present
    Import-Lab $DestinationLab -NoValidation

    $lab = Get-Lab
    $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue
    $destinationDcs = Get-LabVM -Role DC, RootDC, FirstChildDC
    $gatewayPublicIp = Get-AzPublicIpAddress -Name s2sip -ResourceGroupName $sourceResourceGroupName -ErrorAction SilentlyContinue

    if (-not $gatewayPublicIp -or $gatewayPublicIp.IpAddress -notmatch '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
    {
        throw 'Public IP has either not been created or is currently unassigned.'
    }

    if (-not $router)
    {
        throw @'
        No router in your lab. Please redeploy your lab after adding e.g. the following lines:
        Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
        $machineName = "ALS2SVPN$((1..7 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
        Add-LabMachineDefinition -Name $machineName -Roles Routing -NetworkAdapter $netAdapter -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'
'@
    }

    # Step 4: Configure S2S VPN Connection on Router
    $externalAdapters = $router.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

    if ($externalAdapters.Count -ne 1)
    {
        throw "Automatic configuration of VPN gateway can only be done if there is exactly 1 network adapter connected to an external network switch. The machine '$machine' knows about $($externalAdapters.Count) externally connected adapters"
    }

    if ($externalAdapters)
    {
        $mac = $externalAdapters | Select-Object -ExpandProperty MacAddress
        $mac = ($mac | Get-StringSection -SectionSize 2) -join ':'

        if (-not $mac)
        {
            throw ('Get-LabVm returned an empty MAC address for {0}. Cannot continue' -f $router.Name)
        }
    }

    $scriptBlock = {
        param
        (
            $AzureDnsEntry,
            $RemoteAddressSpaces,
            $MacAddress
        )

        if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)
        {
            $externalAdapter = Get-CimInstance -Class Win32_NetworkAdapter -Filter ('MACAddress = "{0}"' -f $MacAddress) |
                Select-Object -ExpandProperty NetConnectionID
        }
        else
        {
            $externalAdapter = Get-WmiObject -Class Win32_NetworkAdapter -Filter ('MACAddress = "{0}"' -f $MacAddress) |
                Select-Object -ExpandProperty NetConnectionID
        }

        Set-Service -Name RemoteAccess -StartupType Automatic
        Start-Service -Name RemoteAccess -ErrorAction SilentlyContinue

        $null = netsh.exe routing ip nat install
        $null = netsh.exe routing ip nat add interface $externalAdapter
        $null = netsh.exe routing ip nat set interface $externalAdapter mode=full

        $status = Get-RemoteAccess -ErrorAction SilentlyContinue
        if (($status.VpnStatus -ne 'Uninstalled') -or ($status.DAStatus -ne 'Uninstalled') -or ($status.SstpProxyStatus -ne 'Uninstalled'))
        {
            Uninstall-RemoteAccess -Force
        }

        if ($status.VpnS2SStatus -ne 'Installed' -or $status.RoutingStatus -ne 'Installed')
        {
            Install-RemoteAccess -VpnType VPNS2S -ErrorAction Stop
        }

        try
        {
            # Try/Catch to catch exception while we have to wait for Install-RemoteAccess to finish up
            Start-Service RemoteAccess -ErrorAction SilentlyContinue
            $azureConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue
        }
        catch
        {
            # If Get-VpnS2SInterface throws HRESULT 800703bc, wait even longer
            Start-Sleep -Seconds 120
            Start-Service RemoteAccess -ErrorAction SilentlyContinue
            $azureConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue
        }


        if (-not $azureConnection)
        {
            $parameters = @{
                Name                 = 'AzureS2S'
                Protocol             = 'IKEv2'
                Destination          = $AzureDnsEntry
                AuthenticationMethod = 'PskOnly'
                SharedSecret         = 'Somepass1'
                NumberOfTries        = 0
                Persistent           = $true
                PassThru             = $true
            }
            $azureConnection = Add-VpnS2SInterface @parameters
        }

        $count = 1

        while ($count -le 3)
        {
            try
            {
                $azureConnection | Connect-VpnS2SInterface -ErrorAction Stop
                $connectionEstablished = $true
            }
            catch
            {
                Write-ScreenInfo -Message "Could not connect to $AzureDnsEntry ($count/3)" -Type Warning
                $connectionEstablished = $false
            }

            $count++
        }

        if (-not $connectionEstablished)
        {
            throw "Error establishing connection to $AzureDnsEntry after 3 tries. Check your NAT settings, internet connectivity and Azure resource group"
        }

        $null = netsh.exe ras set conf confstate = enabled
        $null = netsh.exe routing ip dnsproxy install


        $dialupInterfaceIndex = (Get-NetIPInterface -AddressFamily IPv4 | Where-Object -Property InterfaceAlias -eq 'AzureS2S').ifIndex

        if (-not $dialupInterfaceIndex)
        {
            throw "Connection to $AzureDnsEntry has not been established. Cannot add routes to $($addressSpace -join ',')."
        }

        foreach ($addressSpace in $RemoteAddressSpaces)
        {
            $null = New-NetRoute -DestinationPrefix $addressSpace -InterfaceIndex $dialupInterfaceIndex -AddressFamily IPv4 -NextHop 0.0.0.0 -RouteMetric 1
        }
    }

    Invoke-LabCommand -ActivityName 'Enabling S2S VPN functionality and configuring S2S VPN connection' `
        -ComputerName $router `
        -ScriptBlock $scriptBlock `
        -ArgumentList @($gatewayPublicIp.IpAddress, $AzureAddressSpaces, $mac) `
        -Retries 3 -RetryIntervalInSeconds 10

    # Configure DNS forwarding
    Set-VpnDnsForwarders -SourceLab $SourceLab -DestinationLab $DestinationLab

    Write-LogFunctionExit
}
