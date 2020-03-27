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
	$boolAttrib = $script:un.CreateAttribute('config','type', $script:nsm.LookupNamespace('config'))
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
	$joinUserNode = $script:un.CreateElement('user', $script:nsm.LookupNamespace('un'))
	$joinPasswordNode = $script:un.CreateElement('password', $script:nsm.LookupNamespace('un'))
	$homedirNode = $script:un.CreateElement('mkhomedir', $script:nsm.LookupNamespace('un'))
	$winbindNode = $script:un.CreateElement('winbind', $script:nsm.LookupNamespace('un'))

	$null = $disableDhcp.Attributes.Append($boolAttrib)
	$null = $homedirNode.Attributes.Append($boolAttrib)
	$null = $winbindNode.Attributes.Append($boolAttrib)

	$kdc.InnerText = $DomainName

	$disableDhcp.InnerText = 'true'
	$securityNode.InnerText = 'ADS'
	$shellNode.InnerText = '/bin/bash'
	$guestNode.InnerText = 'no'
	$domainNode.InnerText = $DomainName
	$joinUserNode.InnerText = $Username
	$joinPasswordNode.InnerText = $Password
	$homedirNode.InnerText = 'true'
	$winbindNode.InnerText = 'false'

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

	# SSSD configuration
	$authClientNode = $script:un.CreateElement('auth-client', $script:nsm.LookupNamespace('un'))
	$authClientSssd = $script:un.CreateElement('sssd', $script:nsm.LookupNamespace('un'))
	$authClientLdaps = $script:un.CreateElement('nssldap', $script:nsm.LookupNamespace('un'))
	$sssdConf = $script:un.CreateElement('sssd_conf', $script:nsm.LookupNamespace('un'))
	$sssdConfFile = $script:un.CreateElement('config_file_version', $script:nsm.LookupNamespace('un'))
	$sssdConfServices = $script:un.CreateElement('services', $script:nsm.LookupNamespace('un'))
	$sssdConfNode = $script:un.CreateElement('sssd', $script:nsm.LookupNamespace('un'))
	$sssdConfDomains = $script:un.CreateElement('domains', $script:nsm.LookupNamespace('un'))
	$authDomains = $script:un.CreateElement('auth_domains', $script:nsm.LookupNamespace('un'))
	$authDomain = $script:un.CreateElement('domain', $script:nsm.LookupNamespace('un'))
	$authDomainName = $script:un.CreateElement('domain_name', $script:nsm.LookupNamespace('un'))
	$authDomainIdp = $script:un.CreateElement('id_provider', $script:nsm.LookupNamespace('un'))
	$authDomainUri = $script:un.CreateElement('ldap_uri', $script:nsm.LookupNamespace('un'))

	$authClientSssd.InnerText = 'yes'
	$authClientLdaps.InnerText = 'no'
	$sssdConfFile.InnerText = 2
	$sssdConfServices.InnerText = 'nss, pam'
	$sssdConfDomains.InnerText = $DomainName
	$authDomainName.InnerText = $DomainName
	$authDomainIdp.InnerText = 'ldap'
	$authDomainUri.InnerText = "ldap://$DomainName"

	$authDomain.AppendChild($authDomainName)
	$authDomain.AppendChild($authDomainIdp)
	$authDomain.AppendChild($authDomainUri)
	$authDomains.AppendChild($authDomain)
	$sssdConf.AppendChild($authDomains)

	$sssdConfNode.AppendChild($sssdConfFile)
	$sssdConfNode.AppendChild($sssdConfServices)
	$sssdConfNode.AppendChild($sssdConfDomains)
	$sssdConf.AppendChild($sssdConfNode)

	$authClientNode.AppendChild($authClientSssd)
	$authClientNode.AppendChild($authClientLdaps)
	$authClientNode.AppendChild($sssdConf)
	$script:un.DocumentElement.AppendChild($authClientNode)
}