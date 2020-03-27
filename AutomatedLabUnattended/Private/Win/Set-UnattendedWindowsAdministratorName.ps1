function Set-UnattendedWindowsAdministratorName
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name
	)

	$shellNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node

	$shellNode.UserAccounts.LocalAccounts.LocalAccount.Name = $Name
	$shellNode.UserAccounts.LocalAccounts.LocalAccount.DisplayName = $Name
}