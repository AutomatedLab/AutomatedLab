function Set-LabDefaultToolsPath
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Global:labToolsPath = $Path
}
