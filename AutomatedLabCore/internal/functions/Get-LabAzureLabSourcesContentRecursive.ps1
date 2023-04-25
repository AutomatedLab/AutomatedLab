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

    $temporaryContent = if ($Path)
    {
        $StorageContext | Get-AzStorageFile -Path $Path -ErrorAction SilentlyContinue
    }
    else
    {
        $StorageContext | Get-AzStorageFile
    }

    foreach ($item in $temporaryContent)
    {
        if ($item.CloudFileDirectory)
        {
            $content += $item.CloudFileDirectory
            $content += Get-LabAzureLabSourcesContentRecursive -StorageContext $item
        }
        elseif ($item.CloudFile)
        {
            $content += $item.CloudFile
        }
        else
        {
            continue
        }
    }

    return $content
}
