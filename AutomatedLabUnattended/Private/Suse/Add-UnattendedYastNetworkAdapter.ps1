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

    if (-not $script:un.SelectSingleNode('/un:profile/un:networking/un:dns', $script:nsm))
    {
        $dns = $script:un.CreateElement('dns', $script:nsm.LookupNamespace('un'))
        $host = $script:un.CreateElement('hostname', $script:nsm.LookupNamespace('un'))
        $null = $dns.AppendChild($host)

        if ($DnsDomain)
        {    
            $domain = $script:un.CreateElement('domain', $script:nsm.LookupNamespace('un'))
            $domain.InnerText = $DnsDomain
            $null = $dns.AppendChild($domain)
            $nameservers = $script:un.CreateElement('nameservers', $script:nsm.LookupNamespace('un'))
            $nsAttr = $script:un.CreateAttribute('type', $script:nsm.LookupNamespace('config'))
            $nsAttr.InnerText = 'list'
            $null = $nameservers.Attributes.Append($nsAttr)

            foreach ($ns in $DnsServers)
            {
                $nameserver = $script:un.CreateElement('nameserver', $script:nsm.LookupNamespace('un'))
                $nameserver.InnerText = $ns
                $null = $nameservers.AppendChild($nameserver)
            }

            $null = $dns.AppendChild($nameservers)

            if ($DNSSuffixSearchOrder)
            {
                $searchlist = $script:un.CreateElement('searchlist', $script:nsm.LookupNamespace('un'))
                $nsAttr = $script:un.CreateAttribute('type', $script:nsm.LookupNamespace('config'))
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
    }

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

    $null = $networking.AppendChild($interfaceNode)

    if ($Gateways)
    {
        $routes = $script:un.CreateElement('routes', $script:nsm.LookupNamespace('un'))
        $listAttr = $script:un.CreateAttribute('type', $script:nsm.LookupNamespace('config'))
        $listAttr.InnerText = 'list'
        $null = $routes.Attributes.Append($listAttr)

        foreach ($gateway in $Gateways)
        {
            $routeNode = $script:un.CreateElement('route', $script:nsm.LookupNamespace('un'))
            $destinationNode = $script:un.CreateElement('destination', $script:nsm.LookupNamespace('un'))
            $deviceNode = $script:un.CreateElement('device', $script:nsm.LookupNamespace('un'))
            $gatewayNode = $script:un.CreateElement('gateway', $script:nsm.LookupNamespace('un'))
            $netmask = $script:un.CreateElement('netmask', $script:nsm.LookupNamespace('un'))

            $destinationNode.InnerText = ($IpAddresses | Where-Object {
                [regex]::Match($_.FirstUsable.AddressAsString, "\d{1,3}\.\d{1,3}\.\d{1,3}").Value -eq [regex]::Match($gateway.AddressAsString, "\d{1,3}\.\d{1,3}\.\d{1,3}").Value -and `
                ([int]($_.FirstUsable.AddressAsString -split '\.')[-1] -lt [int]($gateway.AddressAsString -split '\.')[-1] -and [int]($_.LastUsable.AddressAsString -split '\.')[-1] -gt [int]($gateway.AddressAsString -split '\.')[-1])
            }).Network.AddressAsString
            $devicenode.InnerText = $interface
            $gatewayNode.InnerText = $gateway.AddressAsString
            $netmask.InnerText = '-'

            $null = $routeNode.AppendChild($destinationNode)
            $null = $routeNode.AppendChild($devicenode)
            $null = $routeNode.AppendChild($gatewayNode)
            $null = $routeNode.AppendChild($netmask)
            $null = $routes.AppendChild($routeNode)
        }

        $null = $networking.AppendChild($routes)
    }
}
