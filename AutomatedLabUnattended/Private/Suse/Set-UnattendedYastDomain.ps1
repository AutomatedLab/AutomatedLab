function Set-UnattendedYastDomain
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $true)]
		[string]$Username,
		
		[Parameter(Mandatory = $true)]
		[string]$Password
    )
	
	$smbClientNode = $script:un.CreateElement('samba-client', $script:nsm.LookupNamespace('un'))
	$boolAttrib = $script:un.CreateAttribute('type', $script:nsm.LookupNamespace('config'))
    $boolAttrib.InnerText = 'boolean'
	$adNode = $script:un.CreateElement('active_directory', $script:nsm.LookupNamespace('un'))
	$kdc = $script:un.CreateElement('kdc', $script:nsm.LookupNamespace('un'))
	$disableDhcp = $script:un.CreateElement('disable_dhcp_hostname', $script:nsm.LookupNamespace('un'))
	$globalNode = $script:un.CreateElement('global', $script:nsm.LookupNamespace('un'))
	$securityNode = $script:un.CreateElement('security', $script:nsm.LookupNamespace('un'))
	$shellNode = $script:un.CreateElement('template_shell', $script:nsm.LookupNamespace('un'))
	$guestNode = $script:un.CreateElement('usershare_allow_guests', $script:nsm.LookupNamespace('un'))
	$domainNode = $script:un.CreateElement('workgroup', $script:nsm.LookupNamespace('un'))
	$joinNode = $script:un.CreateElement('join', $script:nsm.LookupNamespace('un'))
	$joinUserNode = $script:un.CreateElement('password', $script:nsm.LookupNamespace('un'))
	$joinPasswordNode = $script:un.CreateElement('user', $script:nsm.LookupNamespace('un'))
	$homedirNode = $script:un.CreateElement('mkhomedir', $script:nsm.LookupNamespace('un'))
	$winbindNode = $script:un.CreateElement('winbind', $script:nsm.LookupNamespace('un'))

	$null = $disableDhcp.Attributes.Append($boolAttrib)
	$null = $homedirNode.Attributes.Append($boolAttrib)
	$null = $winbindNode.Attributes.Append($boolAttrib)

	$kdc.InnerText = $DomainName
		
	$disableDhcp.InnerText = 'true'
	$securityNode.InnerText = 'ADC'
	$shellNode.InnerText = '/bin/bash'
	$guestNode.InnerText = 'no'
	$domainNode.InnerText = $DomainName
	$joinUserNode.InnerText = $Username
	$joinPasswordNode.InnerText = $Password	
	$homedirNode.InnerText = 'true'
	$winbindNode.InnerText = 'true'

	$null = $adNode.AppendChild($kdc)
	$null = $globalNode.AppendChild($securityNode)
	$null = $globalNode.AppendChild($shellNode)
	$null = $globalNode.AppendChild($guestNode)
	$null = $globalNode.AppendChild($domainNode)
	$null = $joinNode.AppendChild($joinUserNode)
	$null = $joinNode.AppendChild($joinPasswordNode)
	$null = $smbClientNode.AppendChild($disableDhcp)
	$null = $smbClientNode.AppendChild($globalNode)
	$null = $smbClientNode.AppendChild($adNode)
	$null = $smbClientNode.AppendChild($joinNode)
	$null = $smbClientNode.AppendChild($homedirNode)
	$null = $smbClientNode.AppendChild($winbindNode)

	$null = $script:un.DocumentElement.AppendChild($smbClientNode)
}