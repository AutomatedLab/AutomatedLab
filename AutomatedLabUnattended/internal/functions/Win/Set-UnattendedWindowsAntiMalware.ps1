function Set-UnattendedWindowsAntiMalware
{
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $node = $script:un |
    Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Security-Malware-Windows-Defender"]' -Namespace $ns |
    Select-Object -ExpandProperty Node

    if ($Enabled)
    {
        $node.DisableAntiSpyware = 'true'
    }
    else
    {
        $node.DisableAntiSpyware = 'false'
    }
}