function Export-UnattendedFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$IsKickstart,

        [switch]$IsAutoYast
    )

    if ( $IsKickstart) { Export-UnattendedKickstartFile -Path $Path; return }
    if ( $IsAutoYast) { Export-UnattendedYastFile -Path $Path; return }

    Export-UnattendedWindowsFile -Path $Path
}