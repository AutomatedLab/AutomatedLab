function Import-UnattendedKickstartContent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]
        $Content
    )
    $script:un = $Content
}
