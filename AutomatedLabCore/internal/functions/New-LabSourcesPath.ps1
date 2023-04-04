function New-LabSourcesPath
{
    [CmdletBinding()]
    param
    (
        [string]
        $RelativePath,

        [Microsoft.Azure.Storage.File.CloudFileShare]
        $Share
    )

    $container = Split-Path -Path $RelativePath
    if (-not $container)
    {
        New-AzStorageDirectory -Share $Share -Path $RelativePath -ErrorAction SilentlyContinue
        return
    }

    if (-not (Get-AzStorageFile -Share $Share -Path $container -ErrorAction SilentlyContinue))
    {
        New-LabSourcesPath -RelativePath $container -Share $Share
        New-AzStorageDirectory -Share $Share -Path $container -ErrorAction SilentlyContinue
    }
}
