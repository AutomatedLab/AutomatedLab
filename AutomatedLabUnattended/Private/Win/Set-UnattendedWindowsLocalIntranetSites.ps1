function Set-UnattendedWindowsLocalIntranetSites
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Values
	)

    $ieNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-IE-InternetExplorer"]' -Namespace $ns |
	Select-Object -ExpandProperty Node

    $ieNode.LocalIntranetSites = $Values -join ';'
}