function Add-UnattendedWindowsRenameNetworkAdapters
{
    function Add-XmlGroup
    {
        param
        (
            $XPath,
            $ElementName,
            $Action,
            $KeyValue
        )

        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"

        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'

        $rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node

        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        #[Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, 'add')
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
    }

    function Add-XmlElement
    {
        param
        (
            $rootElement,
            $ElementName,
            $Text,
            $Action,
            $KeyValue
        )

        Write-Debug -Message "XPath=$XPath"
        Write-Debug -Message "ElementName=$ElementName"
        Write-Debug -Message "Text=$Text"

        #$ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
        #$wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'

        #$rootElement = $script:un | Select-Xml -XPath $xPath -Namespace $script:ns | Select-Object -ExpandProperty Node

        $element = $script:un.CreateElement($elementName)
        [Void]$rootElement.AppendChild($element)
        if ($Action)   { [Void]$element.SetAttribute('action', $script:wcmNamespaceUrl, $Action) }
        if ($KeyValue) { [Void]$element.SetAttribute('keyValue', $script:wcmNamespaceUrl, $KeyValue) }
        $element.InnerText = $Text
    }

    $order = (($script:un | Select-Xml -XPath "$WinPENode/un:RunSynchronousCommand" -Namespace $script:ns).node.childnodes.order | Measure-Object -Maximum).maximum
    $order++

    Add-XmlGroup -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -ElementName 'SynchronousCommand' -Action 'add'

    $nodes = ($script:un | Select-Xml -XPath '//un:settings[@pass = "oobeSystem"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]/un:FirstLogonCommands' -Namespace $script:ns  |
	Select-Object -ExpandProperty Node).childnodes

    $order = ($nodes | Measure-Object).count
    $rootElement = $nodes[$order-1]

    Add-XmlElement -RootElement $rootElement -ElementName 'Description' -Text 'Rename network adapters'
    Add-XmlElement -RootElement $rootElement -ElementName 'Order' -Text "$order"
    Add-XmlElement -RootElement $rootElement -ElementName 'CommandLine' -Text 'powershell.exe -executionpolicy bypass -file "c:\RenameNetworkAdapters.ps1"'

}