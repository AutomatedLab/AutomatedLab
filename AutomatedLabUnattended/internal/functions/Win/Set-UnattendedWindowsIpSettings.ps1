function Set-UnattendedWindowsIpSettings
{
	param (
		[string]$IpAddress,

		[string]$Gateway,

		[String[]]$DnsServers,

        [string]$DnsDomain
	)

    $ethernetInterface = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-TCPIP"]/un:Interfaces/un:Interface[un:Identifier = "Ethernet"]' -Namespace $ns |
	Select-Object -ExpandProperty Node

	if (-not $ethernetInterface)
	{
		$ethernetInterface = $script:un |
		Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-TCPIP"]/un:Interfaces/un:Interface[un:Identifier = "Local Area Connection"]' -Namespace $ns |
		Select-Object -ExpandProperty Node
	}

	if ($IpAddress)
	{
		$ethernetInterface.Ipv4Settings.DhcpEnabled = 'false'
		$ethernetInterface.UnicastIpAddresses.IpAddress.InnerText = $IpAddress
	}

	if ($Gateway)
	{
		$InterfaceElement = $script:un |
		Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-TCPIP"]/un:Interfaces/un:Interface' -Namespace $ns |
		Select-Object -ExpandProperty Node

		$RoutesNode = $script:un.CreateElement('Routes')
		[Void]$InterfaceElement.AppendChild($RoutesNode)

		$routes = $script:un |
		Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-TCPIP"]/un:Interfaces/un:Interface/un:Routes' -Namespace $ns |
		Select-Object -ExpandProperty Node

		$routeElement = $script:un.CreateElement('Route')
		$identifierElement = $script:un.CreateElement('Identifier')
		$prefixElement = $script:un.CreateElement('Prefix')
		$nextHopAddressElement = $script:un.CreateElement('NextHopAddress')
		[void]$routeElement.AppendChild($identifierElement)
		[void]$routeElement.AppendChild($prefixElement)
		[void]$routeElement.AppendChild($nextHopAddressElement)

		[Void]$routeElement.SetAttribute('action', $wcmNamespaceUrl, 'add')
		$identifierElement.InnerText = '0'
		$prefixElement.InnerText = '0.0.0.0/0'
		$nextHopAddressElement.InnerText = $Gateway

		[void]$RoutesNode.AppendChild($routeElement)
	}

  <#
    <Routes>
    <Route wcm:action="add">
    <Identifier>0</Identifier>
    <Prefix>0.0.0.0/0</Prefix>
    <NextHopAddress></NextHopAddress>
    </Route>
    </Routes>
  #>

	if ($DnsServers)
	{
		$ethernetInterface = $script:un |
		Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-DNS-Client"]/un:Interfaces/un:Interface[un:Identifier = "Ethernet"]' -Namespace $ns |
		Select-Object -ExpandProperty Node -ErrorAction SilentlyContinue

		if (-not $ethernetInterface)
		{
			$ethernetInterface = $script:un |
			Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-DNS-Client"]/un:Interfaces/un:Interface[un:Identifier = "Local Area Connection"]' -Namespace $ns |
			Select-Object -ExpandProperty Node -ErrorAction SilentlyContinue
		}

    <#
        <DNSServerSearchOrder>
        <IpAddress wcm:action="add" wcm:keyValue="1">10.0.0.10</IpAddress>
        </DNSServerSearchOrder>
    #>

		$dnsServerSearchOrder = $script:un.CreateElement('DNSServerSearchOrder')
		$i = 1
		foreach ($dnsServer in $DnsServers)
		{
			$ipAddressElement = $script:un.CreateElement('IpAddress')
			[Void]$ipAddressElement.SetAttribute('action', $wcmNamespaceUrl, 'add')
			[Void]$ipAddressElement.SetAttribute('keyValue', $wcmNamespaceUrl, "$i")
			$ipAddressElement.InnerText = $dnsServer

			[Void]$dnsServerSearchOrder.AppendChild($ipAddressElement)
			$i++
		}

		[Void]$ethernetInterface.AppendChild($dnsServerSearchOrder)
	}

    <#
        <DNSDomain>something.com</DNSDomain>
    #>
    if ($DnsDomain)
    {
        $ethernetInterface = $script:un |
		Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-DNS-Client"]/un:Interfaces/un:Interface[un:Identifier = "Ethernet"]' -Namespace $ns |
		Select-Object -ExpandProperty Node -ErrorAction SilentlyContinue

		if (-not $ethernetInterface)
		{
			$ethernetInterface = $script:un |
			Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-DNS-Client"]/un:Interfaces/un:Interface[un:Identifier = "Local Area Connection"]' -Namespace $ns |
			Select-Object -ExpandProperty Node -ErrorAction SilentlyContinue
		}

		$dnsDomainElement = $script:un.CreateElement('DNSDomain')
		$dnsDomainElement.InnerText = $DnsDomain

		[Void]$ethernetInterface.AppendChild($dnsDomainElement)
    }
}