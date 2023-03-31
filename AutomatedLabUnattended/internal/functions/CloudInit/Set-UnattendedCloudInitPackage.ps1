function Set-UnattendedCloudInitPackage
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Package
    )

    foreach ($pack in $Package)
    {
        if ($pack -in $script:un.packages) { continue }
        $script:un.packages += $pack
    }
}