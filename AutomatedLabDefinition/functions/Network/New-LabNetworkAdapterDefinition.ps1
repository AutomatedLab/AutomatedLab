function New-LabNetworkAdapterDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'manual')]
    param (
        [Parameter(Mandatory)]
        [string]$VirtualSwitch,

        [string]$InterfaceName,

        [Parameter(ParameterSetName = 'dhcp')]
        [switch]$UseDhcp,

        [Parameter(ParameterSetName = 'manual')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))/([3][0-2]|[1-2][0-9]|[2-9])$')]
        [AutomatedLab.IPNetwork[]]$Ipv4Address,

        [Parameter(ParameterSetName = 'manual')]
        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [AutomatedLab.IPAddress]$Ipv4Gateway,

        [ValidatePattern('^(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))$')]
        [AutomatedLab.IPAddress[]]$Ipv4DNSServers,

        [Parameter(ParameterSetName = 'manual')]
        [AutomatedLab.IPNetwork[]]$IPv6Address,

        [Parameter(ParameterSetName = 'manual')]
        [ValidateRange(1, 128)]
        [int]$IPv6AddressPrefix,

        [Parameter(ParameterSetName = 'manual')]
        [string]$IPv6Gateway,

        [string[]]$IPv6DNSServers,

        [string]$ConnectionSpecificDNSSuffix,

        [boolean]$AppendParentSuffixes,

        [string[]]$AppendDNSSuffixes,

        [boolean]$RegisterInDNS = $true,

        [boolean]$DnsSuffixInDnsRegistration,

        [ValidateSet('Default', 'Enabled', 'Disabled')]
        [string]$NetBIOSOptions = 'Default',

        [ValidateRange(0,4096)]
        [int]$AccessVLANID = 0,

        [boolean]$ManagementAdapter = $false,

        [string]
        $MacAddress,

        [bool]
        $Default
    )

    Write-LogFunctionEntry

    if (-not (Get-LabDefinition))
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }

    $adapter = New-Object -TypeName AutomatedLab.NetworkAdapter
    $adapter.Default = $Default
    $MacAddress = $MacAddress -replace '[\.\-\:]'

    #If the defined interface is flagged as being a Management interface, ignore the virtual switch check as it will not exist yet
    if (-not $ManagementAdapter)
    {
        if ($VirtualSwitch)
        {
            $adapter.VirtualSwitch = Get-LabVirtualNetworkDefinition | Where-Object Name -eq $VirtualSwitch
        }
        else
        {
            $adapter.VirtualSwitch = Get-LabVirtualNetworkDefinition | Select-Object -First 1
        }

        if (-not $adapter.VirtualSwitch)
        {
            throw "Could not find the virtual switch '$VirtualSwitch' nor create one automatically"
        }

        #VLAN Tagging is only currently supported on External switch interfaces. If a VLAN has been provied for an internal switch, throw an error
        if ($adapter.VirtualSwitch.SwitchType -ne 'External' -and $AccessVLANID -ne 0)
        {
            throw "VLAN tagging of interface '$InterfaceName' on non-external virtual switch '$VirtualSwitch' is not supported, either remove the AccessVlanID setting, or assign the interface to an external switch"
        }
    }
    
    if ($InterfaceName)
    {
        $adapter.InterfaceName = $InterfaceName
    }

    foreach ($item in $Ipv4Address)
    {
        $adapter.Ipv4Address.Add($item)
    }

    foreach ($item in $Ipv4DnsServers)
    {
        $adapter.Ipv4DnsServers.Add($item)
    }

    foreach ($item in $Ipv6Address)
    {
        $adapter.Ipv6Address.Add($item)
    }

    foreach ($item in $Ipv6DnsServers)
    {
        $adapter.Ipv6DnsServers.Add($item)
    }

    if ((Get-LabDefinition).DefaultVirtualizationEngine -eq 'HyperV' -and -not $MacAddress)
    {
        $macAddressPrefix = Get-LabConfigurationItem -Name MacAddressPrefix
        [string[]]$macAddressesInUse = (Get-LWHyperVVM | Get-VMNetworkAdapter).MacAddress
        $macAddressesInUse += (Get-LabMachineDefinition -All).NetworkAdapters.MacAddress
        if (-not $script:macIdx) { $script:macIdx = 0 }
        $prefixlength = 12 - $macAddressPrefix.Length
        while ("$macAddressPrefix{0:X$prefixLength}" -f $macIdx -in $macAddressesInUse) { $script:macIdx++ }

        $MacAddress = "$macAddressPrefix{0:X$prefixLength}" -f $script:macIdx++
    }

    if ($Ipv4Gateway) { $adapter.Ipv4Gateway = $Ipv4Gateway }
    if ($Ipv6Gateway) { $adapter.Ipv6Gateway = $Ipv6Gateway }
    if ($MacAddress)  { $adapter.MacAddress = $MacAddress}
    $adapter.ConnectionSpecificDNSSuffix = $ConnectionSpecificDNSSuffix
    $adapter.AppendParentSuffixes        = $AppendParentSuffixes
    $adapter.AppendDNSSuffixes           = $AppendDNSSuffixes
    $adapter.RegisterInDNS               = $RegisterInDNS
    $adapter.DnsSuffixInDnsRegistration  = $DnsSuffixInDnsRegistration
    $adapter.NetBIOSOptions              = $NetBIOSOptions
    $adapter.UseDhcp = $UseDhcp
    $adapter.AccessVLANID = $AccessVLANID

    $adapter

    Write-LogFunctionExit
}
