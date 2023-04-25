function Get-LabAzureLabSourcesContent
{
    [CmdletBinding()]
    param
    (
        [string]
        $RegexFilter,

        # Path relative to labsources file share
        [string]
        $Path,

        [switch]
        $File,

        [switch]
        $Directory
    )

    Test-LabHostConnected -Throw -Quiet

    $azureShare = Get-AzStorageShare -Name labsources -Context (Get-LabAzureLabSourcesStorage).Context

    $params = @{
        StorageContext = $azureShare
    }
    if ($Path) { $params.Path = $Path }

    $content = Get-LabAzureLabSourcesContentRecursive @params

    if (-not [string]::IsNullOrWhiteSpace($RegexFilter))
    {
        $content = $content | Where-Object -FilterScript { $PSItem.Name -match $RegexFilter }
    }

    if ($File)
    {
        $content = $content | Where-Object -FilterScript { $PSItem.GetType().FullName -eq 'Microsoft.Azure.Storage.File.CloudFile' }
    }

    if ($Directory)
    {
        $content = $content | Where-Object -FilterScript { $PSItem.GetType().FullName -eq 'Microsoft.Azure.Storage.File.CloudFileDirectory' }
    }

    $content = $content |
    Add-Member -MemberType ScriptProperty -Name FullName -Value { $this.Uri.AbsoluteUri } -Force -PassThru |
    Add-Member -MemberType ScriptProperty -Name Length -Force -Value { $this.Properties.Length } -PassThru

    return $content
}
