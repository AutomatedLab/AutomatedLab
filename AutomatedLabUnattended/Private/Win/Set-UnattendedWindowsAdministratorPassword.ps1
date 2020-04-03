function Set-UnattendedWindowsAdministratorPassword
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Password
	)

	$shellNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node

	$shellNode.UserAccounts.AdministratorPassword.Value = $Password
	$shellNode.UserAccounts.AdministratorPassword.PlainText = 'true'

	$shellNode.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $Password
}