function Connect-Lab
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [System.String]
        $SourceLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Lab2Lab')]
        [System.String]
        $DestinationLab,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site')]
        $DestinationIpAddress,

        [Parameter(Mandatory = $true, ParameterSetName = 'Site2Site')]
        $PreSharedKey,

        [Parameter()]
        [System.String]
        $NetworkAdapterName = 'Ethernet'
    )
    <#
	- Azure-Lab erhält GW Subnet + VPN Gateway
	- On-Prem-Lab erhält Router (RRAS)
    - Bei zwei Azure-Labs: Zwei GW Subnets + 2 VPN Gateways
    - Bei zwei HyperV Labs: No can do
	- Neues Cmdlet: Connect-Lab -SourceLab -DestinationLab
	- Bei neuem Deployment: Add-LabConnectionDefinition hin zu bestehendem Lab
	- Neues Cmdlet: Disconnect-Lab -SourceLab -DestinationLab
Routing-Maschine/VPNGateway zerstören --> Muss sich in LabXml auch niederschlagen#>

    # VALIDATOR!!! Wenn VNET Peerings vorhanden: Kein nachträgliches erweitern des AdressSpace möglich.
    # VALIDATOR!!! 
    # Routing Setup: Custom Config. VPN, LAN Routing, NAT
    # Neue Props nötig: DestinationIpAddress, PreSharedKey ( Braucht man das wirklich? Zumindest DestinationIP wäre gut, damit man Hybrides Lab überall hin anbinden kann)
    # Azure GW einrichten
    # Übergeordneten CIDR berechnen
			
    # VNet Addressspace umkonfigurieren wenn nötig
    #Get-LWAzureNetworkSwitch -virtualNetwork
    # GatewaySubnet erzeugen
    # Gateway erzeugen
    # Local Gateway erzeugen
    # Addresse: meine eigene IP
    # Remote Adresse: Azure Public IP
    # COnnection hinzufügen VNET mit local gateway
    # Enable RRAS for VPN
    # Add Ikev2 dialup adapter (maybe persistent -to test)
    # VPNtarget = Get-AzureRmPublicIp
    # VPN IPv4 Address = Free address in destination net (?)

    if (Get-Lab -List -notcontains $SourceLab)
    {
        throw "Source lab $SourceLab does not exist."
    }

    if (Get-Lab -List -notcontains $DestinationLab)
    {
        throw "Destination lab $DestinationLab does not exist."
    }

    # Step 1: Import-Lab, check Hypervisor
    $sourceFolder = '{0}\AutomatedLab-Labs\{1}' -f [System.Environment]::GetFolderPath('MyDocuments'), $SourceLab
    $sourceFile = Join-Path -Path $sourceFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $sourceFile)
    {
        throw "Lab.xml is missing for $SourceLab"
    }

    $destinationFolder = '{0}\AutomatedLab-Labs\{1}' -f [System.Environment]::GetFolderPath('MyDocuments'), $DestinationLab
    $destinationFile = Join-Path -Path $destinationFolder -ChildPath Lab.xml -Resolve -ErrorAction SilentlyContinue
    if (-not $destinationFile)
    {
        throw "Lab.xml is missing for $DestinationLab"
    }

    $sourceHypervisor = ([xml](Get-Content $sourceFile)).Lab.DefaultVirtualizationEngine
    $destinationHypervisor = ([xml](Get-Content $destinationFile)).Lab.DefaultVirtualizationEngine

    if (-not ($sourceHypervisor -eq 'Azure' -or $destinationHypervisor -eq 'Azure'))
    {
        throw 'On-premises to on-premises connections are currently not implemented. One or both labs need to be Azure'
    }

    # Step 2: Import the Azure lab and add Gateway-VNET
    if ($sourceHypervisor -eq 'Azure')
    {
        Import-Lab $SourceLab
    }
    else 
    {
        Import-Lab $DestinationLab
    }

    $lab = Get-Lab

    $targetNetwork = $lab.VirtualNetworks | Select-Object -First 1
    $sourceMask = $targetNetwork.AddressSpace.Cidr
    $sourceMaskIp = $targetNetwork.AddressSpace.NetMask
    $superNetMask = $sourceMask - 1

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

    $vNet = Get-LWAzureNetworkSwitch -virtualNetwork $targetNetwork
    $vnet.AddressSpace.AddressPrefixes[0] = "$($superNetIp)/$($superNetMask)"
    [void] ($vnet | Set-AzureRmVirtualNetwork -ErrorAction Stop)

    [void] ($vnet | Add-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -AddressPrefix "$($gatewayNetworkAddress)/$($sourceMask)" | Set-AzureRmVirtualNetwork -ErrorAction Stop)

    # Network expanded. Now for the gateway subnet
    


    # Step 3: Import the HyperV lab and install a Router if not already present
    if ($sourceHypervisor -ne 'Azure')
    {
        Import-Lab $SourceLab
    }
    else 
    {
        Import-Lab $DestinationLab
    }

    $lab = Get-Lab
    $router = Get-LabVm -Role Routing -ErrorAction SilentlyContinue
    $externalNetwork = Get-LabVirtualNetwork | Where-Object {$_.SwitchType -eq 'External'}

    if (-not $externalNetwork)
    {
        Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = $NetworkAdapterName }
        Install-Lab -NetworkSwitches
    }

    if (-not $router)
    {
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $lab.Name
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp

        $routerOs = (Get-LabMachine | Sort-Object {$_.OperatingSystem.Version} -Descending | Select-Object -First 1).OperatingSystem.OperatingSystemName
        Add-LabMachineDefinition -Name "$($lab.Name)-ALS2SVPN" -Roles Routing -NetworkAdapter $netAdapter -OperatingSystem $routerOs

        Install-Lab -VpnGateway
    }    

    # Step 4: Configure S2S VPN Connection on Router

    # Step 5: Find someplace to store Lab Connection Info
}

function Disconnect-Lab
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        $Name
    )

    <# Look up Lab Connection Info
    Remove RRAS Settings for VPN
    Remove Azure VNET Gateway
    #>
}

function Restore-LabConnection
{
    # Wenn der Hypervisor neu gestartet (und vielleicht eine neue öffentliche IP gezogen) wurde
}
