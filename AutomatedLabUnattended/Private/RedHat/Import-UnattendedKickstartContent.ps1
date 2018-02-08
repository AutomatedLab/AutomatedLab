function Import-UnattendedKickstartContent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Content
    )
    $script:un = $Content
}