Write-Host "'after_deploy' block"
if ($IsLinux -or $IsMacOs) { return }
if ( (Get-PackageProvider nuget -Erroraction SilentlyContinue).Version -lt 2.8.5.210)
{
    $provParams = @{
        Name           = 'NuGet'
        MinimumVersion = '2.8.5.210'
        Force          = $true
    }
    $null = Install-PackageProvider @provParams
    $null = Import-PackageProvider @provParams
}

$mainModuleCore = Join-Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/core/AutomatedLab.dll'
$mainModule = Join-Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/full/AutomatedLab.dll'
$sourceLibraryPath = Join-Path $env:APPVEYOR_BUILD_FOLDER 'LabXml/bin/Debug/net462'
$sourceLibraryPathCore = Join-Path $env:APPVEYOR_BUILD_FOLDER 'LabXml/bin/Debug/net6.0'


if (-not (Test-Path $mainModule))
{
    $null = robocopy /S /E $sourceLibraryPath (Split-Path $mainModule)
}
if (-not (Test-Path $mainModuleCore))
{
    $null = robocopy /S /E $sourceLibraryPathCore (Split-Path $mainModuleCore)
}

# Do not publish artifacts anywhere if not on master or develop
if ($env:APPVEYOR_REPO_BRANCH -notin 'master', 'develop')
{
    Add-AppveyorMessage "$env:APPVEYOR_REPO_BRANCH -notin 'master', 'develop' - Exiting build" -Category Information
    Exit-AppveyorBuild
}

# Do not publish artifacts to Gallery or GitHub with every PR
if ($env:APPVEYOR_REPO_BRANCH -in 'master', 'develop' -and -not [string]::IsNullOrWhitespace($env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH) )
{
    Add-AppveyorMessage "$env:APPVEYOR_REPO_BRANCH -in 'master', 'develop', PR coming in from $env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH - Exiting build" -Category Information
    Exit-AppveyorBuild
}

$env:PSModulePath += ";$env:APPVEYOR_BUILD_FOLDER"
foreach ($m in (Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Directory -Exclude AutomatedLab.Common, scriptanalyzer))
{
    if (-not ($m | Get-ChildItem -Filter *.psm1))
    {
        continue
    }

    $publishParams = @{
        Path        = $m.FullName
        NuGetApiKey = $env:NuGetApiKey
        Repository  = 'PSGallery'
        Force       = $true
        Confirm     = $false
    }
    Write-Host "Publishing module '$($m.FullName)'"
    Publish-Module @publishParams
}