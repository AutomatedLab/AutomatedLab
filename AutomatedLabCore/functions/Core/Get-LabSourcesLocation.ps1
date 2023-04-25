function Get-LabSourcesLocation
{
    param
    (
        [switch]$Local
    )

    Get-LabSourcesLocationInternal -Local:$Local
}
