function Import-UnattendedContent
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Content,

        [switch]$IsKickstart,

        [switch]$IsAutoYast
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
