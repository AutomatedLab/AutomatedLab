function Set-UnattendedCloudInitIpSettings
{
    [CmdletBinding()]
    param (
        [string]$IpAddress,

        [string]$Gateway,

        [String[]]$DnsServers,

        [string]$DnsDomain
    )

    $ifName = 'en0'

    $script:un.network.ethernets[$ifName] = @{
        match      = @{
            macAddress = $macAddress
        }
        'set-name' = $ifName
    }

    $adapterAddress = $IpAddress

    if (-not $adapterAddress)
    {
        $script:un.network.ethernets[$ifName].dhcp4 = 'yes'
        $script:un.network.ethernets[$ifName].dhcp6 = 'yes'
    }
    else
    {
        $script:un.network.ethernets[$ifName].addresses = @(
            $IpAddress
        )
    }

    if ($Gateway -and -not $script:un.network.ethernets[$ifName].ContainsKey('routes')) 
    {
        $script:un.network.ethernets[$ifName].routes = @(
            @{
                to  = 'default'
                via = $Gateway
            })
    }

    if ($DnsServers)
    {
        $script:un.network.ethernets[$ifName].nameservers = @{ addresses = $DnsServers }
    }
}