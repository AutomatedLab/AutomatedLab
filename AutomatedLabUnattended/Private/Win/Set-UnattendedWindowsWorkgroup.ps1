function Set-UnattendedWindowsWorkgroup
{
    param
    (
		[Parameter(Mandatory = $true)]
        [string]
        $WorkgroupName
    )

    $idNode = $script:un |
	Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-UnattendedJoin"]/un:Identification' -Namespace $ns |
	Select-Object -ExpandProperty Node

	$idNode.RemoveAll()

	$workGroupNode = $script:un.CreateElement('JoinWorkgroup')
	$workGroupNode.InnerText = $WorkgroupName
    [Void]$idNode.AppendChild($workGroupNode)
}