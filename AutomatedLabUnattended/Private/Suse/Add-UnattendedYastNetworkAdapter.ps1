function Add-UnattendedYastNetworkAdapter
{
    param (
        [string]$Interfacename,

        [AutomatedLab.IPNetwork[]]$IpAddresses,

        [AutomatedLab.IPAddress[]]$Gateways,

        [AutomatedLab.IPAddress[]]$DnsServers,

        [string]$ConnectionSpecificDNSSuffix,

        [string]$DnsDomain,

        [string]$DNSSuffixSearchOrder
    )

    $networking = $script:un.SelectSingleNode('/un:profile/un:networking', $script:nsm)
    $interfaceList = $script:un.SelectSingleNode('/un:profile/un:networking/un:interfaces', $script:nsm)
    $dns = $script:un.SelectSingleNode('/un:profile/un:networking/un:dns', $script:nsm)
    $nameServers = $script:un.SelectSingleNode('/un:profile/un:networking/un:dns/un:nameservers', $script:nsm)
    $routes = $script:un.SelectSingleNode('/un:profile/un:networking/un:routing/un:routes', $script:nsm)
    $hostName = $script:un.CreateElement('hostname', $script:nsm.LookupNamespace('un'))
    $null = $dns.AppendChild($hostName)

    if ($DnsDomain)
    {
        $domain = $script:un.CreateElement('domain', $script:nsm.LookupNamespace('un'))
        $domain.InnerText = $DnsDomain
        $null = $dns.AppendChild($domain)
    }

    if ($DnsServers)
    {
        foreach ($ns in $DnsServers)
        {
            $nameserver = $script:un.CreateElement('nameserver', $script:nsm.LookupNamespace('un'))
            $nameserver.InnerText = $ns
            $null = $nameservers.AppendChild($nameserver)
        }

        if ($DNSSuffixSearchOrder)
        {
            $searchlist = $script:un.CreateElement('searchlist', $script:nsm.LookupNamespace('un'))
            $nsAttr = $script:un.CreateAttribute('config','type', $script:nsm.LookupNamespace('config'))
            $nsAttr.InnerText = 'list'
            $null = $searchlist.Attributes.Append($nsAttr)

            foreach ($suffix in ($DNSSuffixSearchOrder -split ','))
            {
                $suffixEntry = $script:un.CreateElement('search', $script:nsm.LookupNamespace('un'))
                $suffixEntry.InnerText = $suffix
                $null = $searchlist.AppendChild($suffixEntry)
            }

            $null = $dns.AppendChild($searchlist)
        }
    }

    $null = $networking.AppendChild($dns)

    $interface = 'eth0'
    $lastInterface = $script:un.SelectNodes('/un:profile/un:networking/un:interfaces/un:interface/un:device', $script:nsm).InnerText | Sort-Object | Select-Object -Last 1
    if ($lastInterface) {$interface = 'eth{0}' -f ([int]$lastInterface.Substring($lastInterface.Length - 1, 1) + 1)}

    $interfaceNode = $script:un.CreateElement('interface', $script:nsm.LookupNamespace('un'))
    $bootproto = $script:un.CreateElement('bootproto', $script:nsm.LookupNamespace('un'))
    $bootproto.InnerText = 'static'
    $deviceNode = $script:un.CreateElement('device', $script:nsm.LookupNamespace('un'))
    $deviceNode.InnerText = $interface
    $firewallnode = $script:un.CreateElement('firewall', $script:nsm.LookupNamespace('un'))
    $firewallnode.InnerText = 'no'

    $ipaddr = $script:un.CreateElement('ipaddr', $script:nsm.LookupNamespace('un'))
    $netmask = $script:un.CreateElement('netmask', $script:nsm.LookupNamespace('un'))
    $network = $script:un.CreateElement('network', $script:nsm.LookupNamespace('un'))
    $startmode = $script:un.CreateElement('startmode', $script:nsm.LookupNamespace('un'))

    $ipaddr.InnerText = $IpAddresses[0].IpAddress.AddressAsString
    $netmask.InnerText = $IpAddresses[0].Netmask.AddressAsString
    $network.InnerText = $IpAddresses[0].Network.AddressAsString
    $startmode.InnerText = 'auto'

    $null = $interfaceNode.AppendChild($bootproto)
    $null = $interfaceNode.AppendChild($deviceNode)
    $null = $interfaceNode.AppendChild($firewallnode)
    $null = $interfaceNode.AppendChild($ipaddr)
    $null = $interfaceNode.AppendChild($netmask)
    $null = $interfaceNode.AppendChild($network)
    $null = $interfaceNode.AppendChild($startmode)

    if ($IpAddresses.Count -gt 1)
    {
        $aliases = $script:un.CreateElement('aliases', $script:nsm.LookupNamespace('un'))
        $count = 0

        foreach ($additionalAdapter in ($IpAddresses | Select-Object -Skip 1))
        {
            $alias = $script:un.CreateElement("alias$count", $script:nsm.LookupNamespace('un'))
            $ipaddr = $script:un.CreateElement('IPADDR', $script:nsm.LookupNamespace('un'))
            $label = $script:un.CreateElement('LABEL', $script:nsm.LookupNamespace('un'))
            $netmask = $script:un.CreateElement('NETMASK', $script:nsm.LookupNamespace('un'))
            $ipaddr.InnerText = $additionalAdapter.IpAddress.AddressAsString
            $netmask.InnerText = $additionalAdapter.Netmask.AddressAsString
            $label.InnerText = "ip$count"
            $null = $alias.AppendChild($ipaddr)
            $null = $alias.AppendChild($label)
            $null = $alias.AppendChild($netmask)
            $null = $aliases.AppendChild($alias)
            $count++
        }

        $null = $interfaceNode.AppendChild($aliases)
    }

    $null = $interfaceList.AppendChild($interfaceNode)

    if ($Gateways)
    {
        foreach ($gateway in $Gateways)
        {
            $routeNode = $script:un.CreateElement('route', $script:nsm.LookupNamespace('un'))
            $destinationNode = $script:un.CreateElement('destination', $script:nsm.LookupNamespace('un'))
            $deviceNode = $script:un.CreateElement('device', $script:nsm.LookupNamespace('un'))
            $gatewayNode = $script:un.CreateElement('gateway', $script:nsm.LookupNamespace('un'))
            $netmask = $script:un.CreateElement('netmask', $script:nsm.LookupNamespace('un'))

            $destinationNode.InnerText = 'default' # should work for both IPV4 and IPV6 routes

            $devicenode.InnerText = $interface
            $gatewayNode.InnerText = $gateway.AddressAsString
            $netmask.InnerText = '-'

            $null = $routeNode.AppendChild($destinationNode)
            $null = $routeNode.AppendChild($devicenode)
            $null = $routeNode.AppendChild($gatewayNode)
            $null = $routeNode.AppendChild($netmask)
            $null = $routes.AppendChild($routeNode)
        }
    }
}
