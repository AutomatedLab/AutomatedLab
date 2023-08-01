$buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }
$modPath = Get-Item -Path (Join-Path $buildFolder requiredmodules)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
    $sep = [io.path]::PathSeparator
    $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName, $sep, $env:PSModulePath
}

$modPath = Get-Item -Path (Join-Path $buildFolder publish)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
    $sep = [io.path]::PathSeparator
    $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName, $sep, $env:PSModulePath
}

if (-not $IsLinux)
{
    Write-Host "Publishing Modules to AppVeyor"
    $nugetpath = (Join-Path -Path $buildFolder -ChildPath nugets)
    $null = mkdir -Force -Path $nugetpath
    if (-not (Get-PSRepository -Name loc -ErrorAction SilentlyContinue))
    {
        Register-PSRepository -Name loc -SourceLocation $nugetpath -PublishLocation $nugetpath
        Publish-Module -Path (Join-Path -Path $modPath -ChildPath PSFileTransfer) -Repository loc
        foreach ($req in @('newtonsoft.json', 'Pester', 'Ships', 'powershell-yaml', 'PSFramework', 'AutomatedLab.Common'))
        {
            Publish-Module -Name $req -Repository loc -WarningAction SilentlyContinue
        }
        $modules = Find-Module -Repository loc
    }

    foreach ($module in (Get-ChildItem $modPath -Exclude PSFileTransfer | Sort-Object BaseName -Descending))
    {
        Publish-Module -Repository loc -Path $module.FullName -WarningAction SilentlyContinue
    }

    $surplus = @(
        (Join-Path -Path $nugetpath -ChildPath *newtonsoft.json*)
        (Join-Path -Path $nugetpath -ChildPath *AutomatedLab.Common*)
        (Join-Path -Path $nugetpath -ChildPath *Pester*)
        (Join-Path -Path $nugetpath -ChildPath *Ships*)
        (Join-Path -Path $nugetpath -ChildPath *powershell-yaml*)
        (Join-Path -Path $nugetpath -ChildPath *PSFramework*)
    )
    Remove-Item -Path $surplus
    Write-Host "Pushing nuget artifacts"
    foreach ($nougat in (Get-ChildItem -Path $nugetPath))
    {
        Push-AppVeyorArtifact $nougat.FullName -FileName $nougat.Name -DeploymentName ($nougat.BaseName -replace '-preview')
    }

    Unregister-PSRepository -Name loc
    Remove-Item -Force -Recurse -Path $nugetpath

    Write-Host "Pushing installer artifact"
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
    $publishParams = @{
        Path            = $m.FullName
        NuGetApiKey     = $env:NuGetApiKey
        Repository      = 'PSGallery'
        Force           = $true
        Confirm         = $false
    }
    Write-Host "Publishing module '$($m.FullName)' to public gallery"
    Publish-Module @publishParams
}