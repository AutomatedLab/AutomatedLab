function Test-LabPathIsOnLabAzureLabSourcesStorage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-LabHostConnected)) { return $false }

    try
    {
        if (Test-LabAzureLabSourcesStorage)
        {
            $azureLabSources = Get-LabAzureLabSourcesStorage

            return $Path -like "$($azureLabSources.Path)*"
        }
        else
        {
            return $false
        }
    }
    catch
    {
        return $false
    }
}
