function Add-UnattendedWindowsNetworkAdapter
{
	param (
		[string]$Interfacename,

		[AutomatedLab.IPNetwork[]]$IpAddresses,

		[AutomatedLab.IPAddress[]]$Gateways,

		[AutomatedLab.IPAddress[]]$DnsServers,

        [string]$ConnectionSpecificDNSSuffix,

        [string]$DnsDomain,

        [string]$UseDomainNameDevolution,

        [string]$DNSSuffixSearchOrder,

        [string]$EnableAdapterDomainNameRegistration,

        [string]$DisableDynamicUpdate,

        [string]$NetbiosOptions
	)

    function Add-XmlGroup
    {
        param
        (
            [string]$XPath,
            [string]$ElementName,
            [string]$Action,
            [string]$KeyValue
        )

        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"

        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'

        $rootElement = $script:un | Select-Xml -XPath $XPath -Namespace $script:ns | Select-Object -ExpandProperty Node

        $element = $script:un.CreateElement($ElementName, $script:un.DocumentElement.NamespaceURI)
        [Void]$rootElement.AppendChild($element)
        #[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, 'add')
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
    }

    function Add-XmlElement
    {
        param
        (
            [string]$XPath,
            [string]$ElementName,
            [string]$Text,
            [string]$Action,
            [string]$KeyValue
        )

        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
        Write-Debug -Message "Text=$Text"

        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'

        $rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node

        $element = $script:un.CreateElement($elementName, $script:un.DocumentElement.NamespaceURI)
        [Void]$rootElement.AppendChild($element)
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
        $element.InnerText = $Text
    }

    $TCPIPInterfacesNode = '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-TCPIP"]'


    if (-not ($script:un | Select-Xml -XPath "$TCPIPInterfacesNode/un:Interfaces" -Namespace $script:ns | Select-Object -ExpandProperty Node))
    {
        Add-XmlGroup -XPath "$TCPIPInterfacesNode" -ElementName 'Interfaces'
        $order = 1
    }

    Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces" -ElementName 'Interface' -Action 'add'
    Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface" -ElementName 'Ipv4Settings'
    Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv4Settings" -ElementName 'DhcpEnabled' -Text "$(([string](-not ([boolean]($ipAddresses -match '\.')))).ToLower())"
    #Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv4Settings" -ElementName 'Metric' -Text '10'
    #Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv4Settings" -ElementName 'RouterDiscoveryEnabled' -Text 'false'

    Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface" -ElementName 'Ipv6Settings'
    Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv6Settings" -ElementName 'DhcpEnabled' -Text "$(([string](-not ([boolean]($ipAddresses -match ':')))).ToLower())"
    #Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv6Settings" -ElementName 'Metric' -Text '10'
    #Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Ipv6Settings" -ElementName 'RouterDiscoveryEnabled' -Text 'false'

    Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface" -ElementName 'Identifier' -Text "$Interfacename"

    if ($IpAddresses)
	{
        Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface" -ElementName 'UnicastIpAddresses'
        $ipCount = 1
        foreach ($ipAddress in $IpAddresses)
        {
            Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:UnicastIpAddresses" -ElementName 'IpAddress' -Text "$($ipAddress.IpAddress.AddressAsString)/$($ipAddress.Cidr)" -Action 'add' -KeyValue "$(($ipCount++))"
        }
    }

    if ($gateways)
	{
        Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface" -ElementName 'Routes'
        $gatewayCount = 0
        foreach ($gateway in $gateways)
        {
            Add-XmlGroup -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Routes" -ElementName 'Route' -Action 'add'
            Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Routes/un:Route" -ElementName 'Identifier' -Text "$(($gatewayCount++))"
            #Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Routes/un:Route" -ElementName 'Metric' -Text '0'
            Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Routes/un:Route" -ElementName 'NextHopAddress' -Text $gateway
            if ($gateway -match ':')
            {
                $prefix = '::/0'
            }
            else
            {
                $prefix = '0.0.0.0/0'
            }
            Add-XmlElement -XPath "$TCPIPInterfacesNode/un:Interfaces/un:Interface/un:Routes/un:Route" -ElementName 'Prefix' -Text $prefix
        }

    }

    $DNSClientNode = '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-DNS-Client"]'

    #if ($UseDomainNameDevolution)
    #{
    #    Add-XmlElement -XPath "$DNSClientNode" -ElementName 'UseDomainNameDevolution' -Text "$UseDomainNameDevolution"
    #}

    if ($DNSSuffixSearchOrder)
    {
        if (-not ($script:un | Select-Xml -XPath "$DNSClientNode/un:DNSSuffixSearchOrder" -Namespace $script:ns | Select-Object -ExpandProperty Node))
        {
            Add-XmlGroup -XPath "$DNSClientNode" -ElementName 'DNSSuffixSearchOrder' -Action 'add'
            $order = 1
        }
        else
        {
            $nodes = ($script:un | Select-Xml -XPath "$DNSClientNode/un:DNSSuffixSearchOrder" -Namespace $script:ns  | Select-Object -ExpandProperty Node).childnodes
            $order = ($nodes | Measure-Object).count+1
        }

        foreach ($DNSSuffix in $DNSSuffixSearchOrder)
        {
            Add-XmlElement -XPath "$DNSClientNode/un:DNSSuffixSearchOrder" -ElementName 'DomainName' -Text $DNSSuffix -Action 'add' -KeyValue "$(($order++))"
        }
    }

    if (-not ($script:un | Select-Xml -XPath "$DNSClientNode/un:Interfaces" -Namespace $script:ns | Select-Object -ExpandProperty Node))
    {
        Add-XmlGroup -XPath "$DNSClientNode" -ElementName 'Interfaces'
        $order = 1
    }

    Add-XmlGroup -XPath "$DNSClientNode/un:Interfaces" -ElementName 'Interface' -Action 'add'
    Add-XmlElement -XPath "$DNSClientNode/un:Interfaces/un:Interface" -ElementName 'Identifier' -Text "$Interfacename"

    if ($DnsDomain)
    {
        Add-XmlElement -XPath "$DNSClientNode/un:Interfaces/un:Interface" -ElementName 'DNSDomain' -Text "$DnsDomain"
    }

    if ($dnsServers)
	{
        Add-XmlGroup -XPath "$DNSClientNode/un:Interfaces/un:Interface" -ElementName 'DNSServerSearchOrder'
        $dnsServersCount = 1
        foreach ($dnsServer in $dnsServers)
        {
            Add-XmlElement -XPath "$DNSClientNode/un:Interfaces/un:Interface/un:DNSServerSearchOrder" -ElementName 'IpAddress' -Text $dnsServer -Action 'add' -KeyValue "$(($dnsServersCount++))"
        }
    }

    Add-XmlElement -XPath "$DNSClientNode/un:Interfaces/un:Interface" -ElementName 'EnableAdapterDomainNameRegistration' -Text $EnableAdapterDomainNameRegistration

    Add-XmlElement -XPath "$DNSClientNode/un:Interfaces/un:Interface" -ElementName 'DisableDynamicUpdate' -Text $DisableDynamicUpdate


    $NetBTNode = '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-NetBT"]'

    if (-not ($script:un | Select-Xml -XPath "$NetBTNode/un:Interfaces" -Namespace $script:ns | Select-Object -ExpandProperty Node))
    {
        Add-XmlGroup -XPath "$NetBTNode" -ElementName 'Interfaces'
    }

    Add-XmlGroup -XPath "$NetBTNode/un:Interfaces" -ElementName 'Interface' -Action 'add'
    Add-XmlElement -XPath "$NetBTNode/un:Interfaces/un:Interface" -ElementName 'NetbiosOptions' -Text $NetbiosOptions
    Add-XmlElement -XPath "$NetBTNode/un:Interfaces/un:Interface" -ElementName 'Identifier' -Text "$Interfacename"

}