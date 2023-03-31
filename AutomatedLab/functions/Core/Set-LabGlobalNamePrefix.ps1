function Set-LabGlobalNamePrefix
{
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidatePattern("^([\'\""a-zA-Z0-9]){1,4}$|()")]
        [string]$Name
    )

    $Global:labNamePrefix = $Name
}
