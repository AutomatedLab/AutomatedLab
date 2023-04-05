$buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }
$modPath = Get-Item -Path (Join-Path $buildFolder requiredmodules)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName,$sep,$env:PSModulePath
}

$modPath = Get-Item -Path (Join-Path $buildFolder publish)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName,$sep,$env:PSModulePath
}

if (-not $IsLinux)
{
    $Params = @{
        Path    = Join-Path $buildFolder -ChildPath '.build'
        Force   = $true
        Recurse = $false
    }
    Invoke-PSDeploy @Params # Create nuget package artifacts on Windows only, we only need one set
    Add-AppveyorMessage "Locating installer to push as artifact" -Category Information
    $msifile = Get-ChildItem -Path $buildFolder -Recurse -Filter AutomatedLab.msi | Select-Object -First 1
    Push-AppVeyorArtifact $msifile.FullName -FileName $msifile.Name -DeploymentName alinstaller
}

if ($IsLinux)
{
    Add-AppveyorMessage "Locating deb package to push as artifact" -Category Information
    $debFile = Get-ChildItem -Path $buildFolder -Recurse -Filter automatedlab*.deb | Select-Object -First 1
    Push-AppVeyorArtifact $debFile.FullName -FileName $debFile.Name -DeploymentName aldebianpackage

    Add-AppveyorMessage "Locating rpm package to push as artifact" -Category Information
    $debFile = Get-ChildItem -Path $buildFolder -Recurse -Filter automatedlab*.rpm | Select-Object -First 1
    Push-AppVeyorArtifact $debFile.FullName -FileName $debFile.Name -DeploymentName alrpmpackage
}

# Do not publish artifacts anywhere if not on master or develop
if ($env:APPVEYOR_REPO_BRANCH -notin 'master', 'develop')
{
    Add-AppveyorMessage "$env:APPVEYOR_REPO_BRANCH -notin 'master', 'develop' - Exiting build" -Category Information
    Exit-AppveyorBuild
    return
}

# Do not publish artifacts to Gallery or GitHub with every PR
if ($env:APPVEYOR_REPO_BRANCH -in 'master', 'develop' -and -not [string]::IsNullOrWhitespace($env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH) )
{
    Add-AppveyorMessage "$env:APPVEYOR_REPO_BRANCH -in 'master', 'develop', PR coming in from $env:APPVEYOR_PULL_REQUEST_HEAD_REPO_BRANCH - Exiting build" -Category Information
    Exit-AppveyorBuild
    return
}

$publishFolder = Join-Path $buildFolder publish
foreach ($m in (Get-ChildItem -Path $publishFolder -Directory))
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