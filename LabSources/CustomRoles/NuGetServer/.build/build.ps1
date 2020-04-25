param
(
    [string]
    $ProjectPath = (Resolve-Path $PSScriptRoot\..).Path,

    [string[]]
    $Packages,

    [string]
    $Repository = 'PSGallery',

    [string]
    $PackageSourcePath
)

if (-not (Get-Command msbuild -ErrorAction SilentlyContinue))
{
    $msbuildFile = Get-ChildItem -Path / -Filter msbuild.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $env:PATH = $env:PATH + ";$($msbuildFile.Directory.FullName)"
}

$projectFilePath = Join-Path -Path $ProjectPath -ChildPath 'AutomatedLab.Feed\AutomatedLab.Feed.sln'
$publishTarget = New-Item -Path (Join-Path -Path $ProjectPath -ChildPath 'publish') -Force -ItemType Directory
$modulePath = New-Item -Path (Join-Path -Path $publishTarget -ChildPath 'Modules') -Force -ItemType Directory
$packagePath = Join-Path -Path $publishTarget -ChildPath 'Packages'
Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/v4.9.4/nuget.exe' -OutFile (Join-Path -Path $publishTarget -ChildPath nuget.exe) -ErrorAction Stop

& (Join-Path -Path $publishTarget -ChildPath nuget.exe) restore $projectFilePath
msbuild $projectFilePath /p:PublishProfile=FolderProfile /p:DeployOnBuild=true

# Download nuget
# Old version is downloaded because latest version requires .NET 4.8
Save-Module -Name PackageManagement, PowerShellGet, Pester, VoiceCommands -Path $modulePath.FullName -Repository $Repository

Write-Host -ForegroundColor Cyan "Cleaning out $packagePath"
if (Test-Path -Path $packagePath)
{
    Get-ChildItem -Path $packagePath | Remove-Item -Force
}
else
{
    $null = New-Item -ItemType Directory -Path $packagePath
}

$count = $Packages.Count

if ($PackageSourcePath)
{
    $count = (Get-ChildItem -Path $PackageSourcePath -Recurse -Filter *.nupkg | Copy-Item -Destination $packagePath -PassThru -Force).Count
}

$repo = Get-PSRepository -Name $Repository
foreach ($package in $Packages)
{
    $moduleInfo = Find-Module -Name $package -Repository $Repository
    if (([version]$moduleInfo.Version).Build -eq -1)
    {
        $moduleInfo.Version = $moduleInfo.Version + '.0'
    }

    $uri = '{0}{1}/{2}' -f $repo.PublishLocation, $package.ToLower(), $moduleInfo.Version
    $destination = Join-Path -Path $packagePath -ChildPath ('{0}.{1}.nupkg' -f $package, $moduleInfo.Version)
    Invoke-RestMethod -Uri $Uri -OutFile $destination
}

Write-Host -ForegroundColor Cyan "Including $count packages in your NuGet server"
Compress-Archive -Path (Join-Path -Path $publishTarget -Child '*'), (Join-Path $ProjectPath -ChildPath '.build\test.ps1') -DestinationPath (Join-Path $publishTarget -ChildPath Deploy.zip) -Force
Compress-Archive -Path (Join-Path $publishTarget -ChildPath Deploy.zip), (Join-Path $ProjectPath -ChildPath '.build\deploy.ps1') -DestinationPath (Join-Path $publishTarget -ChildPath BuildOutput.zip) -Force
