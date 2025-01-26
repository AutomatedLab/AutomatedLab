function Test-LabAzureLabSourcesStorage
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param ( )

    Test-LabHostConnected -Throw -Quiet

    if ((Get-LabDefinition -ErrorAction SilentlyContinue).AzureSettings.IsAzureStack -or (Get-Lab -ErrorAction SilentlyContinue).AzureSettings.IsAzureStack) { return $false }

    $azureLabSources = Get-LabAzureLabSourcesStorage -ErrorAction SilentlyContinue

    if (-not $azureLabSources)
    {
        Write-Warning "Azure LabSources storage '$($azureLabSources.StorageAccountName)' does not exist in the subscription '$($azureLabSources.SubscriptionName)'"
        return $false
    }

    if (-not $azureLabSources.AllowSharedKeyAccess)
    {
        Write-Warning "Azure LabSources storage '$($azureLabSources.StorageAccountName)' does not allow shared key access"
        return $false
    }

    $azureStorageShare = Get-AzStorageShare -Context $azureLabSources.Context -ErrorAction SilentlyContinue

    [bool]$azureStorageShare
}
