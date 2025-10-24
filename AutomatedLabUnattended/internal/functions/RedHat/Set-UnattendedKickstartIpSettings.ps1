function Set-UnattendedKickstartIpSettings
{
    param (
        [string]$IpAddress,

        [string]$Gateway,

        [String[]]$DnsServers,

        [string]$DnsDomain
    )

    if (-not $IpAddress)
    {
        $configurationItem = "network --bootproto=dhcp"
    }
    else
    {
        $configurationItem = "network --bootproto=static --ip={0}" -f $IpAddress
    }

    if ($Gateway)
    {
        $configurationItem += ' --gateway={0}' -f $Gateway
    }

    $configurationItem += if ($DnsServers)
    {
        ' --nameserver={0} --ipv4-dns-search={1}' -f ($DnsServers.AddressAsString -join ','), $DnsDomain
    }
    else
    {
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
