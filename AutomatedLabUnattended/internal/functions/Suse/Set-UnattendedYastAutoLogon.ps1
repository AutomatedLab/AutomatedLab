function Set-UnattendedYastAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password
    )

	$logonNode = $script:un.CreateElement('login_settings', $script:nsm.LookupNamespace('un'))
	$autoLogon = $script:un.CreateElement('autologin_user', $script:nsm.LookupNamespace('un'))
	$autologon.InnerText = '{0}\{1}' -f $DomainName, $Username
	$null = $logonNode.AppendChild($autoLogon)
	$null = $script:un.DocumentElement.AppendChild($logonNode)
}