param(
    [Parameter(Mandatory)]
    [string]$FeatureName,

    [string[]]$RemoteFolders
)

Install-WindowsFeature -Name XPS-Viewer

foreach ($folder in $RemoteFolders)
{
    New-Item -ItemType Directory -Path $folder
}