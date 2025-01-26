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

    $script:un['autoinstall']['network']['ethernets'][$ifName] = @{
        match      = @{
            macAddress = $macAddress
        }
        'set-name' = $ifName
    }

    $adapterAddress = $IpAddress

    if (-not $adapterAddress)
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['dhcp4'] = 'yes'
        $script:un['autoinstall']['network']['ethernets'][$ifName]['dhcp6'] = 'yes'
    }
    else
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['addresses'] = @(
            $IpAddress
        )
    }

    if ($Gateway -and -not $script:un['autoinstall']['network']['ethernets'][$ifName].ContainsKey('routes')) 
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['routes'] = @(
            @{
                to  = 'default'
                via = $Gateway
            })
    }

    if ($DnsServers)
    {
        $script:un['autoinstall']['network']['ethernets'][$ifName]['nameservers'] = @{ addresses = $DnsServers }
    }
}