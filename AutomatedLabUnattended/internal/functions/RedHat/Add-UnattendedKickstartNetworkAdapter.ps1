function Add-UnattendedKickstartNetworkAdapter {
    param (
        [string]$Interfacename,

        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [AutomatedLab.IPAddress[]]$Gateways,

        [AutomatedLab.IPAddress[]]$DnsServers
    )

    $linuxInterfaceName = ($Interfacename -replace '-', ':').ToLower()
    $adapterAddress = $IpAddresses | Select-Object -First 1

    if (-not $adapterAddress) {
        $configurationItem = "network --bootproto=dhcp --device={0}" -f $linuxInterfaceName
    }
    else {
        $configurationItem = "network --bootproto=static --device={0} --ip={1} --netmask={2}" -f $linuxInterfaceName, $adapterAddress.IPAddress.AddressAsString, $adapterAddress.Netmask
    }

    if ($Gateways) {
        $configurationItem += ' --gateway={0}' -f ($Gateways.AddressAsString -join ',')
    }

    $configurationItem += if ($DnsServers | Where-Object AddressAsString -ne '0.0.0.0') {
        ' --nameserver={0}' -f ($DnsServers.AddressAsString -join ',')
    }
    else {
        ' --nodns'
    }

    $existingLine = $script:un | Where-Object { $_ -match 'network' }

    if ($existingLine -like '*bootproto*') {
        $index = $script:un.IndexOf($existingLine)
        $null = $existingLine -match '(?<HostName>--hostname=\w+)'
        $script:un[$index] = '{0} {1}' -f $configurationItem, $Matches.HostName
        return
    }

    $script:un.Add($configurationItem)
}
