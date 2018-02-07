function Add-UnattendedKickstartNetworkAdapter
{
	param (
		[string]$Interfacename,

		[AutomatedLab.IPNetwork[]]$IpAddresses,
		
		[AutomatedLab.IPAddress[]]$Gateways,
		
		[AutomatedLab.IPAddress[]]$DnsServers
    )
    
    $linuxInterfaceName = ($Interfacename -replace '-',':').ToLower()
    $adapterAddress = $IpAddresses | Select-Object -First 1
    $netMask = ConvertTo-Mask -Masklength $adapterAddress.Cidr

    if (-not $adapterAdress)
    {
        $configurationItem = "`nnetwork --bootproto=dhcp"
    }
    else
    {
        $configurationItem = "`nnetwork --bootproto=static --device={0} --ip={1} --netmask={2}" -f $linuxInterfaceName,$adapterAddress.AddressAsString,$netMask
    }

    if ($Gateways)
    {
        $configurationItem += ' --gateway={0}' -f ($Gateways.AddressAsString -join ',')
    }

    $configurationItem += if ($DnsServers)
    {
        ' --nameserver={0}' -f ($DnsServers.AddressAsString -join ',')
    }
    else
    {
        ' --nodns'
    }

    $configurationItem += '--hostname=%HOSTNAME%'

    $script:un += $configurationItem
}