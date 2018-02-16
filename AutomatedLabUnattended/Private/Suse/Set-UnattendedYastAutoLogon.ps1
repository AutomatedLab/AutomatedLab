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
	
	$autoLogon = $script:un.CreateElement('autologin_user', $script:nsm.LookupNamespace('un'))
	$autologon.InnerText = '{0}\{1}' -f $DomainName, $Username
	$null = $script:un.DocumentElement.AppendChild($autoLogon)
}