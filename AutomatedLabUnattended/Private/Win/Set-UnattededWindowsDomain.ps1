function Set-UnattendedWindowsDomain
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$DomainName,

		[Parameter(Mandatory = $true)]
		[string]$Username,

		[Parameter(Mandatory = $true)]
		[string]$Password
	)

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
