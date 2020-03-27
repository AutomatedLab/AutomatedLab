function Set-UnattendedWindowsAutoLogon
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password
	)

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
