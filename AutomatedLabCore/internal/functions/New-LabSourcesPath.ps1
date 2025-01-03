function New-LabSourcesPath
{
    [CmdletBinding()]
    param
    (
        [string]
        $RelativePath,

        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageFileShare]
        $Share
    )

    $container = Split-Path -Path $RelativePath
    if (-not $container)
    {
        New-AzStorageDirectory -ShareClient $share.ShareClient -Context $Share.Context -Path $RelativePath -ErrorAction SilentlyContinue
        return
    }

    if (-not (Get-AzStorageFile -ShareClient $Share.ShareClient -Context $share.Context -Path $container -ErrorAction SilentlyContinue))
    {
        New-LabSourcesPath -RelativePath $container -Share $Share
        New-AzStorageDirectory -ShareClient $share.ShareClient -Context $Share.Context -Path $container -ErrorAction SilentlyContinue
    }
}
