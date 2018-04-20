param(
    [Parameter(Mandatory)]
    [string[]]$LocalSoftwareFolder
)

Remove-Item -Path $LocalSoftwareFolder -Recurse -Force