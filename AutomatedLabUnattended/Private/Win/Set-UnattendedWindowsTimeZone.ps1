function Set-UnattendedWindowsTimeZone
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TimeZone
    )

    $component = $script:un |
        Select-Xml -XPath '//un:settings[@pass = "specialize"]/un:component[@name = "Microsoft-Windows-Shell-Setup"]' -Namespace $ns |
        Select-Object -ExpandProperty Node

    $component.TimeZone = $TimeZone
}
