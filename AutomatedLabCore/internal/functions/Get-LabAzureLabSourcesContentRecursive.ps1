function Get-LabAzureLabSourcesContentRecursive
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]$StorageContext,

        # Path relative to labsources file share
        [string]
        $Path
    )

    Test-LabHostConnected -Throw -Quiet

    $content = @()

    $param = @{
        Context = $StorageContext.Context
    }
    if ($Path)
    {
        $param.Path = $Path
        $param.ErrorAction = 'SilentlyContinue'
    }
    
    if ($StorageContext.ShareDirectoryClient) { $param.ShareDirectoryClient = $StorageContext.ShareDirectoryClient}
    if ($StorageContext.ShareClient) { $param.ShareClient = $StorageContext.ShareClient}
    $temporaryContent = Get-AzStorageFile @param

    foreach ($item in $temporaryContent)
    {
        if ($item.ShareDirectoryClient)
        {
            $content += $item
            $content += Get-LabAzureLabSourcesContentRecursive -StorageContext $item
        }
        elseif ($item.ShareFileClient)
        {
            $content += $item
        }
        else
        {
            continue
        }
    }

    return $content
}
