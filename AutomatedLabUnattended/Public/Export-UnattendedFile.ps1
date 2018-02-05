function Export-UnattendedFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(ParameterSetName = 'Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName = 'Yast')]
        [switch]
        $IsAutoYast
    )
    
    if ( $IsKickstart) { Export-UnattendedKickstartFile -Path $Path; return }
    if ( $IsAutoYast) { Export-UnattendedYastFile -Path $Path; return }
    
    Export-UnattendedKickstartFile -Path $Path
}