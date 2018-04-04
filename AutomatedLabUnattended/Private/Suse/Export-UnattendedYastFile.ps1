function Export-UnattendedYastFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un.Save($Path)
}