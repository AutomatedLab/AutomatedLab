function Add-UnattendedYastSynchronousCommand {
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$Description
    )

    # Init Scripts - run after the system is up and running
    $scriptsNode = $script:un.SelectSingleNode('/un:profile/un:scripts/un:init-scripts', $script:nsm)

    # Add new script with GUID as filename (mandatory if more than one script)
    $scriptNode = $script:un.CreateElement('script', $script:nsm.LookupNamespace('un'))
    $mapAttr = $script:un.CreateAttribute('t')
    $mapAttr.InnerText = 'map'
    $null = $scriptNode.Attributes.Append($mapAttr)
    
    $fileNameNode = $script:un.CreateElement('file-name', $script:nsm.LookupNamespace('un'))
    $fileNameNode.InnerText = [guid]::NewGuid().ToString()
    $null = $scriptNode.AppendChild($fileNameNode)

    # Add "source" node with CDATA content of $Command
    $sourceNode = $script:un.CreateElement('source', $script:nsm.LookupNamespace('un'))
    $cdata = $script:un.CreateCDataSection($Command)
    $null = $sourceNode.AppendChild($cdata)
    $null = $scriptNode.AppendChild($sourceNode)

    # Append the script node to the scripts node
    $null = $scriptsNode.AppendChild($scriptNode)
}