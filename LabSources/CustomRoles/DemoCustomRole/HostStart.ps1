param(
    [Parameter(Mandatory)]
    [string]$LocalSoftwareFolder,

    [Parameter(Mandatory)]
    [string]$NotepadDownloadUrl,

    [Parameter(Mandatory)]
    [string]$ComputerName
)

Import-Lab -Name $data.Name

New-Item -ItemType Directory -Path $LocalSoftwareFolder -Force | Out-Null

$notepadInstaller = Get-LabInternetFile -Uri $NotepadDownloadUrl -Path $LocalSoftwareFolder -PassThru

Install-LabSoftwarePackage -ComputerName $ComputerName -Path $notepadInstaller.FullName -CommandLine /S