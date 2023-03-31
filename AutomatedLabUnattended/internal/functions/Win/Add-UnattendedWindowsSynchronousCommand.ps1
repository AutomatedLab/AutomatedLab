function Add-UnattendedWindowsSynchronousCommand
{
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $highestOrder = ($un | Select-Xml -Namespace $ns -XPath //un:RunSynchronous).Node.RunSynchronousCommand.Order |
    Sort-Object -Property { [int]$_ } -Descending |
    Select-Object -First 1

    $runSynchronousNode = ($un | Select-Xml -Namespace $ns -XPath //un:RunSynchronous).Node

    $runSynchronousCommandNode = $un.CreateElement('RunSynchronousCommand')

    [Void]$runSynchronousCommandNode.SetAttribute('action', $wcmNamespaceUrl, 'add')

    $runSynchronousCommandDescriptionNode = $un.CreateElement('Description')
    $runSynchronousCommandDescriptionNode.InnerText = $Description

    $runSynchronousCommandOrderNode = $un.CreateElement('Order')
    $runSynchronousCommandOrderNode.InnerText = ([int]$highestOrder + 1)

    $runSynchronousCommandPathNode = $un.CreateElement('Path')
    $runSynchronousCommandPathNode.InnerText = $Command

    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandDescriptionNode)
    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandOrderNode)
    [void]$runSynchronousCommandNode.AppendChild($runSynchronousCommandPathNode)

    [void]$runSynchronousNode.AppendChild($runSynchronousCommandNode)
}