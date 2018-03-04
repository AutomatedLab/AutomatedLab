param(
    [Parameter(Mandatory)]
    [string]$FeatureName,

    [string[]]$Folders
)

Install-WindowsFeature -Name XPS-Viewer

foreach ($folder in $Folders)
{
    mkdir -Path $folder
}