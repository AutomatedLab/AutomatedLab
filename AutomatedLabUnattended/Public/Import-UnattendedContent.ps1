function Import-UnattendedContent
{
    param (
        [Parameter(Mandatory = $true)]
        [xml]
        $Content,
        
        [Parameter(ParameterSetName = 'Kickstart')]
        [switch]
        $IsKickstart,

        [Parameter(ParameterSetName = 'Yast')]
        [switch]
        $IsAutoYast
    )    
    
    if ($IsKickstart)
    {
        Import-UnattendedKickstartContent -Content $Content
        return
    }
    
    if ($IsAutoYast)
    {
        Import-UnattendedYastContent -Content $Content        
        return        
    }

    Import-UnattendedWindowsContent -Content $Content
}
