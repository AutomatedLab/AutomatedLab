function Set-UnattendedWindowsProductKey
{
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProductKey
	)

	$setupNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
	Select-Object -ExpandProperty Node

	$productKeyNode = $script:un.CreateElement('ProductKey')
	$productKeyNode.InnerText = $ProductKey
	[Void]$setupNode.AppendChild($productKeyNode)
}