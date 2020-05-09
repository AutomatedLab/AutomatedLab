function Connect-Lab
{
    [CmdletBinding(DefaultParameterSetName = 'Lab2Lab')]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $SourceLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Lab2Lab', Position = 1)]
        [System.String]
        $DestinationLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site', Position = 1)]
        [System.String]
        $DestinationIpAddress,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site', Position = 2)]
        [System.String]
        $PreSharedKey,

        [Parameter(ParameterSetName = 'Site2Site', Position = 3)]
        [System.String[]]
        $AddressSpace,

        [Parameter(Mandatory = $false)]
        [System.String]
        $NetworkAdapterName = 'Ethernet'
    )

    Write-LogFunctionEntry

    if ((Get-Lab -List) -notcontains $SourceLab)
    {
        throw "Source lab $SourceLab does not exist."
    }

    if ($DestinationIpAddress)
    {
        Write-PSFMessage -Message ('Connecting {0} to {1}' -f $SourceLab, $DestinationIpAddress)
        Connect-OnPremisesWithEndpoint -LabName $SourceLab -IPAddress $DestinationIpAddress -AddressSpace $AddressSpace -Psk $PreSharedKey
        return
    }

    if ((Get-Lab -List) -notcontains $DestinationLab)
    {
        throw "Destination lab $DestinationLab does not exist."
    }

    $sourceFolder ="$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$SourceLab"
    $sourceFile = Join-Path -Path $sourceFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $sourceFile)
    {
        throw "Lab.xml is missing for $SourceLab"
    }

    $destinationFolder = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$DestinationLab"
    $destinationFile = Join-Path -Path $destinationFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $destinationFile)
    {
        throw "Lab.xml is missing for $DestinationLab"
    }

    $sourceHypervisor = ([xml](Get-Content $sourceFile)).Lab.DefaultVirtualizationEngine
    $sourceRoutedAddressSpaces = ([xml](Get-Content $sourceFile)).Lab.VirtualNetworks.VirtualNetwork.AddressSpace | ForEach-Object {
        if (-not [System.String]::IsNullOrWhiteSpace($_.IpAddress.AddressAsString))
        {
            "$($_.IpAddress.AddressAsString)/$($_.SerializationCidr)"
        }
    }

    $destinationHypervisor = ([xml](Get-Content $destinationFile)).Lab.DefaultVirtualizationEngine
    $destinationRoutedAddressSpaces = ([xml](Get-Content $destinationFile)).Lab.VirtualNetworks.VirtualNetwork.AddressSpace | ForEach-Object {
        if (-not [System.String]::IsNullOrWhiteSpace($_.IpAddress.AddressAsString))
        {
            "$($_.IpAddress.AddressAsString)/$($_.SerializationCidr)"
        }
    }

    Write-PSFMessage -Message ('Source Hypervisor: {0}, Destination Hypervisor: {1}' -f $sourceHypervisor, $destinationHypervisor)

    if (-not ($sourceHypervisor -eq 'Azure' -or $destinationHypervisor -eq 'Azure'))
    {
        throw 'On-premises to on-premises connections are currently not implemented. One or both labs need to be Azure'
    }

    if ($sourceHypervisor -eq 'Azure')
    {
        $connectionParameters = @{
            SourceLab           = $SourceLab
            DestinationLab      = $DestinationLab
            AzureAddressSpaces  = $sourceRoutedAddressSpaces
            OnPremAddressSpaces = $destinationRoutedAddressSpaces
        }
    }
    else
    {
        $connectionParameters = @{
            SourceLab           = $DestinationLab
            DestinationLab      = $SourceLab
            AzureAddressSpaces  = $destinationRoutedAddressSpaces
            OnPremAddressSpaces = $sourceRoutedAddressSpaces
        }
    }

    if ($sourceHypervisor -eq 'Azure' -and $destinationHypervisor -eq 'Azure')
    {
        Write-PSFMessage -Message ('Connecting Azure lab {0} to Azure lab {1}' -f $SourceLab, $DestinationLab)
        Connect-AzureLab -SourceLab $SourceLab -DestinationLab $DestinationLab
        return
    }

    Write-PSFMessage -Message ('Connecting on-premises lab to Azure lab. Source: {0} <-> Destination {1}' -f $SourceLab, $DestinationLab)
    Connect-OnPremisesWithAzure @connectionParameters

    Write-LogFunctionExit
}

function Disconnect-Lab
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        $SourceLab,

        [Parameter(Mandatory)]
        $DestinationLab
    )

    Write-LogFunctionEntry

    foreach ($LabName in @($SourceLab, $DestinationLab))
    {
        Import-Lab -Name $LabName -ErrorAction Stop -NoValidation
        $lab = Get-Lab

        Invoke-LabCommand -ActivityName 'Remove conditional forwarders' -ComputerName (Get-LabVM -Role RootDC) -ScriptBlock {
            Get-DnsServerZone | Where-Object -Property ZoneType -EQ Forwarder | Remove-DnsServerZone -Force
        }

        if ($lab.DefaultVirtualizationEngine -eq 'Azure')
        {
            $resourceGroupName = (Get-LabAzureDefaultResourceGroup).ResourceGroupName

            Write-PSFMessage -Message ('Removing VPN resources in Azure lab {0}, Resource group {1}' -f $lab.Name, $resourceGroupName)

            $connection = Get-AzVirtualNetworkGatewayConnection -Name s2sconnection -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $gw = Get-AzVirtualNetworkGateway -Name s2sgw -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $localgw = Get-AzLocalNetworkGateway -Name onpremgw -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
            $ip = Get-AzPublicIpAddress -Name s2sip -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

            if ($connection)
            {
                $connection | Remove-AzVirtualNetworkGatewayConnection -Force
            }

            if ($gw)
            {
                $gw | Remove-AzVirtualNetworkGateway -Force
            }

            if ($ip)
            {
                $ip | Remove-AzPublicIpAddress -Force
            }

            if ($localgw)
            {
                $localgw | Remove-AzLocalNetworkGateway -Force
            }
        }
        else
        {
            $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue

            if (-not $router)
            {
                # How did this even work...
                continue
            }

            Write-PSFMessage -Message ('Disabling S2SVPN in on-prem lab {0} on router {1}' -f $lab.Name, $router.Name)

            Invoke-LabCommand -ActivityName "Disabling S2S on $($router.Name)" -ComputerName $router -ScriptBlock {
                Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue | Remove-VpnS2SInterface -Force -ErrorAction SilentlyContinue
                Uninstall-RemoteAccess -VpnType VPNS2S -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-LogFunctionExit
}

function Restore-LabConnection
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

    if ((Get-Lab -List) -notcontains $SourceLab)
    {
        throw "Source lab $SourceLab does not exist."
    }

    if ((Get-Lab -List) -notcontains $DestinationLab)
    {
        throw "Destination lab $DestinationLab does not exist."
    }

    $sourceFolder = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$SourceLab"
    $sourceFile = Join-Path -Path $sourceFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $sourceFile)
    {
        throw "Lab.xml is missing for $SourceLab"
    }

    $destinationFolder = "$((Get-LabConfigurationItem -Name LabAppDataRoot))\Labs\$DestinationLab"
    $destinationFile = Join-Path -Path $destinationFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $destinationFile)
    {
        throw "Lab.xml is missing for $DestinationLab"
    }

    $sourceHypervisor = ([xml](Get-Content $sourceFile)).Lab.DefaultVirtualizationEngine
    $destinationHypervisor = ([xml](Get-Content $destinationFile)).Lab.DefaultVirtualizationEngine

    if ($sourceHypervisor -eq 'Azure')
    {
        $source = $SourceLab
        $destination = $DestinationLab
    }
    else
    {
        $source = $DestinationLab
        $destination = $SourceLab
    }

    Write-PSFMessage -Message "Checking Azure lab $source"
    Import-Lab -Name $source -NoValidation
    $resourceGroup = (Get-LabAzureDefaultResourceGroup).ResourceGroupName

    $localGateway = Get-AzLocalNetworkGateway -Name onpremgw -ResourceGroupName $resourceGroup -ErrorAction Stop
    $vpnGatewayIp = Get-AzPublicIpAddress -Name s2sip -ResourceGroupName $resourceGroup -ErrorAction Stop

    try
    {
        $labIp = Get-PublicIpAddress -ErrorAction Stop
    }
    catch
    {
        Write-ScreenInfo -Message 'Public IP address could not be determined. Reconnect-Lab will probably not work.' -Type Warning
    }

    if ($localGateway.GatewayIpAddress -ne $labIp)
    {
        Write-PSFMessage -Message "Gateway address $($localGateway.GatewayIpAddress) does not match local IP $labIP and will be changed"
        $localGateway.GatewayIpAddress = $labIp
        [void] ($localGateway | Set-AzLocalNetworkGateway)
    }

    Import-Lab -Name $destination -NoValidation
    $router = Get-LabVm -Role Routing

    Invoke-LabCommand -ActivityName 'Checking S2S connection' -ComputerName $router -ScriptBlock {
        param
        (
            [System.String]
            $azureDestination
        )

        $s2sConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction Stop -Verbose

        if ($s2sConnection.Destination -notcontains $azureDestination)
        {
            $s2sConnection.Destination += $azureDestination
            $s2sConnection | Set-VpnS2SInterface -Verbose
        }
    } -ArgumentList @($vpnGatewayIp.IpAddress)
}

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

function Connect-OnPremisesWithAzure
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

        $externalAdapter = Get-WmiObject -Class Win32_NetworkAdapter -Filter ('MACAddress = "{0}"' -f $MacAddress) |
            Select-Object -ExpandProperty NetConnectionID

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

function Connect-OnPremisesWithEndpoint
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LabName,
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationHost,
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AddressSpace,
        [Parameter(Mandatory = $true)]
        [System.String]
        $Psk
    )

    Write-LogFunctionEntry
    Import-Lab $LabName -NoValidation

    $lab = Get-Lab
    $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue

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

    $externalAdapters = $router.NetworkAdapters | Where-Object { $_.VirtualSwitch.SwitchType -eq 'External' }

    if ($externalAdapters.Count -ne 1)
    {
        throw "Automatic configuration of VPN gateway can only be done if there is exactly 1 network adapter connected to an external network switch. The machine '$machine' knows about $($externalAdapters.Count) externally connected adapters"
    }

    $externalAdapter = $externalAdapters[0]
    $mac = $externalAdapter.MacAddress
    $mac = ($mac | Get-StringSection -SectionSize 2) -join '-'

    $scriptBlock = {
        param
        (
            $DestinationHost,
            $RemoteAddressSpaces
        )

        $status = Get-RemoteAccess -ErrorAction SilentlyContinue
        if ($status.VpnS2SStatus -ne 'Installed' -or $status.RoutingStatus -ne 'Installed')
        {
            Install-RemoteAccess -VpnType VPNS2S -ErrorAction Stop
        }

        Restart-Service -Name RemoteAccess

        $remoteConnection = Get-VpnS2SInterface -Name AzureS2S -ErrorAction SilentlyContinue

        if (-not $remoteConnection)
        {
            $parameters = @{
                Name                 = 'ALS2S'
                Protocol             = 'IKEv2'
                Destination          = $DestinationHost
                AuthenticationMethod = 'PskOnly'
                SharedSecret         = 'Somepass1'
                NumberOfTries        = 0
                Persistent           = $true
                PassThru             = $true
            }
            $remoteConnection = Add-VpnS2SInterface @parameters
        }

        $remoteConnection | Connect-VpnS2SInterface -ErrorAction Stop

        $dialupInterfaceIndex = (Get-NetIPInterface | Where-Object -Property InterfaceAlias -eq 'ALS2S').ifIndex

        foreach ($addressSpace in $RemoteAddressSpaces)
        {
            New-NetRoute -DestinationPrefix $addressSpace -InterfaceIndex $dialupInterfaceIndex -AddressFamily IPv4 -NextHop 0.0.0.0 -RouteMetric 1
        }
    }

    Invoke-LabCommand -ActivityName 'Enabling S2S VPN functionality and configuring S2S VPN connection' `
        -ComputerName $router `
        -ScriptBlock $scriptBlock `
        -ArgumentList @($DestinationHost, $AddressSpace) `
        -Retries 3 -RetryIntervalInSeconds 10

    Write-LogFunctionExit
}

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

function Set-VpnDnsForwarders
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

    Import-Lab $SourceLab -NoValidation
    $sourceDcs = Get-LabVM -Role DC, RootDC, FirstChildDC

    Import-Lab $DestinationLab -NoValidation
    $destinationDcs = Get-LabVM -Role DC, RootDC, FirstChildDC

    $forestNames = @($sourceDcs) + @($destinationDcs) | Where-Object { $_.Roles.Name -Contains 'RootDC'} | Select-Object -ExpandProperty DomainName
    $forwarders = Get-FullMesh -List $forestNames

    foreach ($forwarder in $forwarders)
    {
        $targetMachine = @($sourceDcs) + @($destinationDcs) | Where-Object { $_.Roles.Name -contains 'RootDC' -and $_.DomainName -eq $forwarder.Source }
        $machineExists = Get-LabVM | Where-Object {$_.Name -eq $targetMachine.Name -and $_.IpV4Address -eq $targetMachine.IpV4Address}

        if (-not $machineExists)
        {
            if ((Get-Lab).Name -eq $SourceLab)
            {
                Import-Lab -Name $DestinationLab -NoValidation
            }
            else
            {
                Import-Lab -Name $SourceLab -NoValidation
            }
        }

        $masterServers = @($sourceDcs) + @($destinationDcs) | Where-Object {
            ($_.Roles.Name -contains 'RootDC' -or $_.Roles.Name -contains 'FirstChildDC' -or $_.Roles.Name -contains 'DC') -and $_.DomainName -eq $forwarder.Destination
        }

        $cmd = @"
            Write-PSFMessage "Creating a DNS forwarder on server '$env:COMPUTERNAME'. Forwarder name is '$($forwarder.Destination)' and target DNS server is '$($masterServers.IpV4Address)'..."
            dnscmd localhost /ZoneAdd $($forwarder.Destination) /Forwarder $($masterServers.IpV4Address)
            Write-PSFMessage '...done'
"@

        Invoke-LabCommand -ComputerName $targetMachine -ScriptBlock ([scriptblock]::Create($cmd)) -NoDisplay
    }
}
