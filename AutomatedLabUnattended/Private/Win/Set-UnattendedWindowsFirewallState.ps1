function Set-UnattendedWindowsFirewallState
{
	param (
		[Parameter(Mandatory = $true)]
		[boolean]$State
	)

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