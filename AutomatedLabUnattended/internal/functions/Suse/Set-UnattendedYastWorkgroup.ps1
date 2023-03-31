function Set-UnattendedYastWorkgroup
{
    param
    (
		[Parameter(Mandatory = $true)]
        [string]
        $WorkgroupName
    )

    $smbClientNode = $script:un.CreateElement('samba-client', $script:nsm.LookupNamespace('un'))
	$boolAttrib = $script:un.CreateAttribute('config','type', $script:nsm.LookupNamespace('config'))
    $boolAttrib.InnerText = 'boolean'
	$disableDhcp = $script:un.CreateElement('disable_dhcp_hostname', $script:nsm.LookupNamespace('un'))
	$globalNode = $script:un.CreateElement('global', $script:nsm.LookupNamespace('un'))
	$securityNode = $script:un.CreateElement('security', $script:nsm.LookupNamespace('un'))
	$shellNode = $script:un.CreateElement('template_shell', $script:nsm.LookupNamespace('un'))
	$guestNode = $script:un.CreateElement('usershare_allow_guests', $script:nsm.LookupNamespace('un'))
	$domainNode = $script:un.CreateElement('workgroup', $script:nsm.LookupNamespace('un'))
	$homedirNode = $script:un.CreateElement('mkhomedir', $script:nsm.LookupNamespace('un'))
	$winbindNode = $script:un.CreateElement('winbind', $script:nsm.LookupNamespace('un'))

	$null = $disableDhcp.Attributes.Append($boolAttrib)
	$null = $homedirNode.Attributes.Append($boolAttrib)
	$null = $winbindNode.Attributes.Append($boolAttrib)

	$disableDhcp.InnerText = 'true'
	$securityNode.InnerText = 'domain'
	$shellNode.InnerText = '/bin/bash'
	$guestNode.InnerText = 'no'
	$domainNode.InnerText = $DomainName
	$homedirNode.InnerText = 'true'
	$winbindNode.InnerText = 'true'

	$null = $globalNode.AppendChild($securityNode)
	$null = $globalNode.AppendChild($shellNode)
	$null = $globalNode.AppendChild($guestNode)
    $null = $globalNode.AppendChild($domainNode)
    $null = $smbClientNode.AppendChild($disableDhcp)
	$null = $smbClientNode.AppendChild($globalNode)
	$null = $smbClientNode.AppendChild($homedirNode)
	$null = $smbClientNode.AppendChild($winbindNode)

	$null = $script:un.DocumentElement.AppendChild($smbClientNode)
}