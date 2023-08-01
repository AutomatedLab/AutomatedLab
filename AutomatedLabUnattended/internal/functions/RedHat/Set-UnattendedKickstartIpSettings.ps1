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
        ' --nameserver={0}' -f ($DnsServers.AddressAsString -join ',')
    }
    else
    {
        ' --nodns'
    }

    $script:un.Add($configurationItem)
}
