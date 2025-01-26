function Add-UnattendedCloudInitNetworkAdapter
{
    param (
        [string]$InterfaceName,

        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [AutomatedLab.IPAddress[]]$Gateways,

        [AutomatedLab.IPAddress[]]$DnsServers
    )

    $macAddress = ($Interfacename -replace '-', ':').ToLower()
    if (-not $script:un['autoinstall']['network'].ContainsKey('ethernets`'))
    {
        $script:un['autoinstall']['network']['ethernets'] = @{ }
    }

    if ($script:un['autoinstall']['network']['ethernets'].Keys.Count -eq 0)
    {
        $ifName = 'en0'
    }
    else
    {
        [int]$lastIfIndex = ($script:un['autoinstall']['network']['ethernets'].Keys.GetEnumerator() | Sort-Object | Select-Object -Last 1) -replace 'en'
        $lastIfIndex++
        $ifName = 'en{0}' -f $lastIfIndex
    }

    $script:un['autoinstall']['network']['ethernets'][$ifName] = @{
        match      = @{
            macaddress = $macAddress
        }
        'set-name' = $ifName
    }

    $adapterAddress = $IpAddresses | Select-Object -First 1

    if (-not $adapterAddress)
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['dhcp4'] = 'yes'
        $script:un['autoinstall']['network']['ethernets'][$ifName]['dhcp6'] = 'yes'
    }
    else
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['addresses'] = @()
        foreach ($ip in $IpAddresses)
        {
            $script:un['autoinstall']['network']['ethernets'][$ifName]['addresses'] += '{0}/{1}' -f $ip.IPAddress.AddressAsString, $ip.SerializationCidr
        }
    }

    if ($Gateways -and -not $script:un['autoinstall']['network']['ethernets'][$ifName].ContainsKey('routes')) { $script:un['autoinstall']['network']['ethernets'][$ifName].routes = @() }
    foreach ($gw in $Gateways)
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['routes'] += @{
            to  = 'default'
            via = $gw.AddressAsString
        }
    }

    if ($DnsServers)
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['nameservers'] = @{ addresses = [string[]]($DnsServers.AddressAsString) }
    }
}
