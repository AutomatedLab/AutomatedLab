

#region Get-UnattendedContent

#endregion Get-UnattendedContent

#region Export-UnattendedFile

#endregion Export-UnattendedFile

#region Set-UnattendedComputerName

#endregion

#region Set-UnattendedUserLocale
function Set-UnattendedUserLocale
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$UserLocale
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$component = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-International-Core"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	#this is for getting the input locale strings like '0409:00000409'
	$component.UserLocale = $UserLocale
	$inputLocale = @((New-WinUserLanguageList -Language $UserLocale).InputMethodTips)
	$inputLocale += (New-WinUserLanguageList -Language 'en-us').InputMethodTips
	
	if ($inputLocale)
	{
		$component.InputLocale = ($inputLocale -join ';')
	}
}
#endregion Set-UnattendedUserLocale

#region Set-UnattendedTimeZone
function Set-UnattendedTimeZone
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$TimeZone
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$component = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$component.TimeZone = $TimeZone
}
#endregion Set-UnattendedTimeZone

#region Set-UnattendedWorkgroup
function Set-UnattendedWorkgroup
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$WorkgroupName
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$idNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-UnattendedJoin"]/un:Identification' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$idNode.RemoveAll()
	
	$workGroupNode = $script:un.CreateElement('JoinWorkgroup')
	$workGroupNode.InnerText = $WorkgroupName
	[Void]$idNode.AppendChild($workGroupNode)
}
#endregion Set-UnattendedWorkgroup

#region Set-UnattendedDomain
function Set-UnattendedDomain
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true)]
		[string]$Username,
		
		[Parameter(Mandatory = $true)]
		[string]$Password
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$idNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-UnattendedJoin"]/un:Identification' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$idNode.RemoveAll()
	
	$joinDomainNode = $script:un.CreateElement('JoinDomain')
	$joinDomainNode.InnerText = $DomainName
	
	$credentialsNode = $script:un.CreateElement('Credentials')
	$domainNode = $script:un.CreateElement('Domain')
	$domainNode.InnerText = $DomainName
	$userNameNode = $script:un.CreateElement('Username')
	$userNameNode.InnerText = $Username
	$passwordNode = $script:un.CreateElement('Password')
	$passwordNode.InnerText = $Password
	
	[Void]$credentialsNode.AppendChild($domainNode)
	[Void]$credentialsNode.AppendChild($userNameNode)
	[Void]$credentialsNode.AppendChild($passwordNode)
	
	[Void]$idNode.AppendChild($credentialsNode)
	[Void]$idNode.AppendChild($joinDomainNode)
}
#endregion Set-UnattendedDomain

#region Set-UnattendedAutoLogon
function Set-UnattendedAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true)]
		[string]$Username,
		
		[Parameter(Mandatory = $true)]
		[string]$Password
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$shellNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$autoLogonNode = $script:un.CreateElement('AutoLogon')
	
	$passwordNode = $script:un.CreateElement('Password')
	$passwordValueNode = $script:un.CreateElement('Value')
	$passwordValueNode.InnerText = $Password
	
	$domainNode = $script:un.CreateElement('Domain')
	$domainNode.InnerText = $DomainName
	
	$enabledNode = $script:un.CreateElement('Enabled')
	$enabledNode.InnerText = 'true'
	
	$logonCount = $script:un.CreateElement('LogonCount')
	$logonCount.InnerText = '9999'
	
	$userNameNode = $script:un.CreateElement('Username')
	$userNameNode.InnerText = $Username
	
	[Void]$autoLogonNode.AppendChild($passwordNode)
	[Void]$passwordNode.AppendChild($passwordValueNode)
	[Void]$autoLogonNode.AppendChild($domainNode)
	[Void]$autoLogonNode.AppendChild($enabledNode)
	[Void]$autoLogonNode.AppendChild($logonCount)
	[Void]$autoLogonNode.AppendChild($userNameNode)
	
	[Void]$shellNode.AppendChild($autoLogonNode)
}
#endregion Set-UnattendedAutoLogon

#region Set-UnattendedAdministratorPassword
function Set-UnattendedAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$shellNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$shellNode.UserAccounts.AdministratorPassword.Value = $Password
	$shellNode.UserAccounts.AdministratorPassword.PlainText = 'true'
	
	$shellNode.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $Password
}
#endregion Set-UnattendedAdministratorPassword

#region Set-UnattendedAdministratorName
function Set-UnattendedAdministratorName
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$shellNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$shellNode.UserAccounts.LocalAccounts.LocalAccount.Name = $Name
	$shellNode.UserAccounts.LocalAccounts.LocalAccount.DisplayName = $Name
}
#endregion Set-UnattendedAdministratorName

#region Set-UnattendedComputerName
function Set-UnattendedIpSettings
{
	param (
		[string]$IpAddress,
		
		[string]$Gateway,
		
		[String[]]$DnsServers,

        [string]$DnsDomain
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	
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
#endregion

#region Add-UnattendedNetworkAdapter
function Add-UnattendedNetworkAdapter
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
    
    
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    <#
    if (-not ($script:un | Select-Xml -XPath '//un:settings[@pass = "specialize"]' -Namespace $script:ns | Select-Object -ExpandProperty Node))
    {
        Add-XmlGroup -XPath "$TCPIPInterfacesNode" -ElementName 'Microsoft-Windows-TCPIP'
        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        </component>
    }
    #>

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
#endregion Add-UnattendedNetworkAdapter

#region Add-UnattendedRenameNetworkAdapters
function Add-UnattendedRenameNetworkAdapters
{
    function Add-XmlGroup
    {
        param
        (
            $XPath,
            $ElementName,
            $Action,
            $KeyValue
        )
    
        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
 
        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
        
        $rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node
    
        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        #[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, 'add')
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
    }

    function Add-XmlElement
    {
        param
        (
            $rootElement,
            $ElementName,
            $Text,
            $Action,
            $KeyValue
        )
    
        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
        Write-Debug -Message "Text=$Text"
 
        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
        
        #$rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node
    
        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
        $element.InnerText = $Text
    }
    
    
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    
    $order = (($script:un | Select-Xml -XPath "$WinPENode/un:RunSynchronousCommand" -Namespace $script:ns).node.childnodes.order | measure -Maximum).maximum
    $order++

    Add-XmlGroup -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -ElementName 'SynchronousCommand' -Action 'add'
    
    $nodes = ($script:un | Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -Namespace $script:ns  | 
	Select-Object -ExpandProperty Node).childnodes

    $order = ($nodes | Measure-Object).count
    $rootElement = $nodes[$order-1]
    
    Add-XmlElement -RootElement $rootElement -ElementName 'Description' -Text 'Rename network adapters'
    Add-XmlElement -RootElement $rootElement -ElementName 'Order' -Text "$order"
    Add-XmlElement -RootElement $rootElement -ElementName 'CommandLine' -Text 'powershell.exe -executionpolicy bypass -file "c:\RenameNetworkAdapters.ps1"'
    
}
#endregion Add-UnattendedRenameNetworkAdapters

#OBSOLETE
#region Add-UnattendedRenameNetworkAdapter
function Add-UnattendedRenameNetworkAdapter
{
	param (
		[string]$OldInterfaceName,

		[string]$NewInterfaceName
	)
	
    function Add-XmlGroup
    {
        param
        (
            $XPath,
            $ElementName,
            $Action,
            $KeyValue
        )
    
        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
 
        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
        
        $rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node
    
        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        #[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, 'add')
        if ($Action)
		{
			[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action)
		}

        if ($KeyValue)
		{
			[Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue)
		}
    }

    function Add-XmlElement
    {
        param
        (
            $rootElement,
            $ElementName,
            $Text,
            $Action,
            $KeyValue
        )
    
        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
        Write-Debug -Message "Text=$Text"
 
        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
        
        #$rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node
    
        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        if ($Action)
		{
			[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action)
		}

        if ($KeyValue)
		{
			[Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue)
		}
        $element.InnerText = $Text
    }
    
    
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    $order = (($script:un | Select-Xml -XPath "$TCPIPInterfacesNode/un:RunSynchronous" -Namespace $script:ns).node.childnodes.order | measure -Maximum).maximum
    $order++

    Add-XmlGroup -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -ElementName 'SynchronousCommand' -Action 'add'
    
    $nodes = ($script:un | Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -Namespace $script:ns  | Select-Object -ExpandProperty Node).childnodes
    $order = ($nodes | Measure-Object).count
    $rootElement = $nodes[$order-1]
    
    Add-XmlElement -RootElement $rootElement -ElementName 'Description' -Text "Rename adapter ""$OldInterfaceName"" newname=""$NewInterfaceName"""
    Add-XmlElement -RootElement $rootElement -ElementName 'Order' -Text "$order"
    Add-XmlElement -RootElement $rootElement -ElementName 'CommandLine' -Text "cmd /c netsh interface set interface name=""$OldInterfaceName"" newname=""$NewInterfaceName"""
}
#endregion Add-UnattendedRenameNetworkAdapter

#region Set-UnattendedProductKey
function Set-UnattendedProductKey
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProductKey
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
	$setupNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$productKeyNode = $script:un.CreateElement('ProductKey')
	$productKeyNode.InnerText = $ProductKey
	[Void]$setupNode.AppendChild($productKeyNode)
}
#endregion Set-UnattendedProductKey

#region Add-UnattendedSynchronousCommand
function Add-UnattendedSynchronousCommand
{
    param (
        [Parameter(Mandatory)]
        [string]$Command,
		
        [Parameter(Mandatory)]
        [string]$Description
    )
	
    if (-not $script:un)
    {
        Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
        return
    }
	
    $highestOrder = ($un | Select-Xml -Namespace $ns -XPath //un:RunSynchronous).Node.RunSynchronousCommand.Order |
    Sort-Object -Property { [int]$_ } -Descending |
    Select-Object -First 1
    
    $runSynchronousNode = ($un | Select-Xml -Namespace $ns -XPath //un:RunSynchronous).Node
	
    $runSynchronousCommandNode = $un.CreateElement('RunSynchronousCommand')
	
    [Void]$runSynchronousCommandNode.SetAttribute('action', $wcmNamespaceUrl, 'add')
	
    $runSynchronousCommandDescriptionNode = $un.CreateElement('Description')
    $runSynchronousCommandDescriptionNode.InnerText = $Description
	
    $runSynchronousCommandOrderNode = $un.CreateElement('Order')
    $runSynchronousCommandOrderNode.InnerText = ([int]$highestOrder + 1)
	
    $runSynchronousCommandPathNode = $un.CreateElement('Path')
    $runSynchronousCommandPathNode.InnerText = $Command
	
    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandDescriptionNode)
    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandOrderNode)
    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandPathNode)
	
    [void]$runSynchronousNode.AppendChild($runSynchronousCommandNode)
}
#endregion Add-UnattendedSynchronousCommand

#region Set-WindowsFirewallState
function Set-WindowsFirewallState
{
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    $setupNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Networking-MPSSVC-Svc"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
	$WindowsFirewallStateNode = $script:un.CreateElement('DomainProfile_EnableFirewall')
	$WindowsFirewallStateNode.InnerText = [string]$State
	[Void]$setupNode.AppendChild($WindowsFirewallStateNode)

	$WindowsFirewallStateNode = $script:un.CreateElement('PrivateProfile_EnableFirewall')
	$WindowsFirewallStateNode.InnerText = [string]$State
	[Void]$setupNode.AppendChild($WindowsFirewallStateNode)

	$WindowsFirewallStateNode = $script:un.CreateElement('PublicProfile_EnableFirewall')
	$WindowsFirewallStateNode.InnerText = [string]$State
	[Void]$setupNode.AppendChild($WindowsFirewallStateNode)
}
#endregion Set-WindowsFirewallState

#region Set-LocalIntranetSites
function Set-LocalIntranetSites
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Values
	)
	
	if (-not $script:un)
	{
		Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
		return
	}
	
    $ieNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-IE-InternetExplorer"]' -Namespace $ns |
	Select-Object -ExpandProperty Node
	
    $ieNode.LocalIntranetSites = $Values -join ';'
}
#endregion Set-LocalIntranetSites

#region Set-UnattendedWindowsDefender
function Set-UnattendedWindowsDefender
{
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )
	
    if (-not $script:un)
    {
        Write-Error 'No unattended file imported. Please use Import-UnattendedFile first'
        return
    }
	
    $node = $script:un |
    Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Security-Malware-Windows-Defender"]' -Namespace $ns |
    Select-Object -ExpandProperty Node
	
    if ($Enabled)
    {
        $node.DisableAntiSpyware = 'true'
    }
    else
    {
        $node.DisableAntiSpyware = 'false'
    }
}
#endregion Set-UnattendedWindowsDefender