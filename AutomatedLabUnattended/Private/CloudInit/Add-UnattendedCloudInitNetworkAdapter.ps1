function Add-UnattendedCloudInitNetworkAdapter
{
    param (
        [string]$InterfaceName,

        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [AutomatedLab.IPAddress[]]$Gateways,

        [AutomatedLab.IPAddress[]]$DnsServers
    )

    $macAddress = ($Interfacename -replace '-', ':').ToLower()
    if (-not $script:un.network.network.ContainsKey('ethernets`'))
    {
        $script:un.network.network.ethernets = @{ }
    }

    if ($script:un.network.network.ethernets.Keys.Count -eq 0)
    {
        $ifName = 'en0'
    }
    else
    {
        [int]$lastIfIndex = ($script:un.network.network.ethernets.Keys.GetEnumerator() | Sort-Object | Select-Object -Last 1) -replace 'en'
        $lastIfIndex++
        $ifName = 'en{0}' -f $lastIfIndex
    }

    $script:un.network.network.ethernets[$ifName] = @{
        match      = @{
            macAddress = $macAddress
        }
        'set-name' = $ifName
    }

    $adapterAddress = $IpAddresses | Select-Object -First 1

    if (-not $adapterAddress)
    {
        $script:un.network.network.ethernets[$ifName].dhcp4 = 'yes'
        $script:un.network.network.ethernets[$ifName].dhcp6 = 'yes'
    }
    else
    {
        $script:un.network.network.ethernets[$ifName].addresses = @()
        foreach ($ip in $IpAddresses)
        {
            $script:un.network.network.ethernets[$ifName].addresses += '{0}/{1}' -f $ip.IPAddress.AddressAsString, $ip.Netmask
        }
    }

    if ($Gateways -and -not $script:un.network.network.ethernets[$ifName].ContainsKey('routes')) { $script:un.network.network.ethernets[$ifName].routes = @() }
    foreach ($gw in $Gateways)
    {
        $script:un.network.network.ethernets[$ifName].routes += @{
            to  = 'default'
            via = $gw.AddressAsString
        }
    }

    if ($DnsServers)
    {
        $script:un.network.network.ethernets[$ifName].nameservers = @{ addresses = $DnsServers.AddressAsString }
    }
}
