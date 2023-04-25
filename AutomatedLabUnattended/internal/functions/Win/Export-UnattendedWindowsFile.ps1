function Export-UnattendedWindowsFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un.Save($Path)
}