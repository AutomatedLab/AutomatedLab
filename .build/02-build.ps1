﻿# Build modules for installer
function BuildModule
{
    param
    (
        $Name,
        [switch]
        $SkipStringBuilder
    )

    if ([string]::IsNullOrWhiteSpace($Name))
    {
        throw "Module name may not be empty"
    }

    #region Handle Working Directory DefaultsHostsFile
    $WorkingDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\$Name"
    $publishDir = New-Item -Path $PSScriptRoot -Name "..\publish" -ItemType Directory -Force
    #endregion Handle Working Directory Defaults

    # Prepare publish folder
    Write-Host "Creating and populating $Name publishing directory"
    Copy-Item -Path "$($WorkingDirectory)" -Destination (Join-Path $publishDir.FullName $Name) -Recurse -Force

    if ($env:APPVEYOR_BUILD_VERSION)
    {
        $para = @{
            Path          = Join-Path $publishDir.FullName "$Name\$Name.psd1"
            ModuleVersion = $env:APPVEYOR_BUILD_VERSION
        }
        if ($env:APPVEYOR_REPO_BRANCH -ne "master")
        {
            $para['Prerelease'] = 'preview'
        }
        Update-ModuleManifest @para
    }

    if ($SkipStringBuilder) { return }

    #region Gather text data to compile
    $text = @()

    # Gather commands
    Get-ChildItem -Path "$($publishDir.FullName)\$Name\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
        $text += [System.IO.File]::ReadAllText($_.FullName)
    }
    Get-ChildItem -Path "$($publishDir.FullName)\$Name\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
        $text += [System.IO.File]::ReadAllText($_.FullName)
    }

    # Gather scripts
    Get-ChildItem -Path "$($publishDir.FullName)\$Name\internal\scripts\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
        $text += [System.IO.File]::ReadAllText($_.FullName)
    }

    #region Update the psm1 file & Cleanup
    [System.IO.File]::WriteAllText("$($publishDir.FullName)\$Name\$Name.psm1", ($text -join "`n`n"), [System.Text.Encoding]::UTF8)
    Remove-Item -Path "$($publishDir.FullName)\$Name\internal" -Recurse -Force
    Remove-Item -Path "$($publishDir.FullName)\$Name\functions" -Recurse -Force
    #endregion Update the psm1 file & Cleanup
}

$buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }
$projPath = Join-Path $buildFolder  -ChildPath 'LabXml/LabXml.csproj' -Resolve -ErrorAction Stop
$modPath = Get-Item -Path (Join-Path $buildFolder requiredmodules)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
    $sep = [io.path]::PathSeparator
    $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName, $sep, $env:PSModulePath
}

if (Test-Path -Path  (Join-Path -Path $buildFolder -ChildPath publish))
{
    Remove-Item -Path (Join-Path -Path $buildFolder -ChildPath publish) -Recurse -Force
}

$modPath = Join-Path $buildFolder publish
if (-not $env:PSModulePath.Contains($modpath))
{
    $sep = [io.path]::PathSeparator
    $env:PSModulePath = '{0}{1}{2}' -f $modPath, $sep, $env:PSModulePath
}

$modules = 'AutomatedLabCore','AutomatedLabUnattended', 'PSLog', 'PSFileTransfer', 'AutomatedLabDefinition', 'AutomatedLabWorker', 'HostsFile', 'AutomatedLabNotifications', 'AutomatedLabTest', 'AutomatedLab', 'AutomatedLab.Ships', 'AutomatedLab.Recipe'
foreach ($module in $modules)
{
    BuildModule -Name $module -SkipStringBuilder:$($module -in 'AutomatedLab','AutomatedLab.Ships')
}

$null = dotnet publish $projPath -f net6.0 -o (Join-Path -Path $buildFolder 'publish/AutomatedLabCore/lib/core')
if (-not $IsLinux)
{
    $null = dotnet restore $projPath
    $null = dotnet publish $projPath -f net462 -o (Join-Path -Path $buildFolder 'publish/AutomatedLabCore/lib/full') 
}

Copy-Item -Path (Join-Path -Path $buildFolder 'Assets/ProductKeys.xml') -Destination (Join-Path -Path $buildFolder 'publish/AutomatedLabCore/ProductKeys.xml')

# Build solution after AppVeyor patched it - local build needs to do that themselves
# Solution builds installer (Windows only) and requires all modules to be packaged before producing proper artefact
if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
{
    if (-not (Get-Command msbuild -ErrorAction SilentlyContinue))
    {
        $msbuild = get-childitem -path C:\ -recurse -file -ErrorAction SilentlyContinue -Filter msbuild.exe | select -first 1
        if (-not $msbuild) { throw 'No msbuild, cannot build solution - we use WiX3' }
        Set-Alias -Name msbuild -Value $msbuild.FullName
    }
    if (-not (Get-Command nuget -ErrorAction SilentlyContinue))
    {
        $nuget = get-childitem -path C:\ -recurse -file -ErrorAction SilentlyContinue -Filter nuget.exe | select -first 1
        if (-not $nuget) { throw 'No nuget, cannot build solution' }
        Set-Alias -Name nuget -Value $nuget.FullName
    }

    nuget restore AutomatedLab.sln
    msbuild AutomatedLab.sln
}

if ([System.Environment]::OSVersion.Platform -eq 'Unix')
{
    dotnet build -f net6.0 LabXml/LabXml.csproj
}

if (-not $IsLinux)
{
    return
}

# Build debian package structure
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/local/share/powershell/Modules -Force
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Stores -Force
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Labs -Force
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force
$null = New-Item -ItemType Directory -Path ./deb/automatedlab/DEBIAN -Force

# Create control file
@"
Package: automatedlab
Version: $env:APPVEYOR_BUILD_VERSION
Maintainer: https://automatedlab.org
Description: Installs the pwsh module AutomatedLab in the global module directory
Section: utils
Architecture: amd64
Bugs: https://github.com/automatedlab/automatedlab/issues
Homepage: https://automatedlab.org
Pre-Depends: powershell
Installed-Size: $('{0:0}' -f ((Get-ChildItem -Path (Join-Path $buildFolder -ChildPath publish) -File -Recurse | Measure-Object Length -Sum).Sum /1mb))
"@ | Set-Content -Path ./deb/automatedlab/DEBIAN/control -Encoding UTF8

# Copy content
foreach ($source in [IO.DirectoryInfo[]]@('./publish/AutomatedLab', './publish/AutomatedLab.Recipe', './publish/AutomatedLab.Ships', './publish/AutomatedLabDefinition', './publish/AutomatedLabNotifications', './publish/AutomatedLabTest', './publish/AutomatedLabUnattended', './publish/AutomatedLabWorker', './publish/HostsFile', './publish/PSLog', './publish/PSFileTransfer'))
{
    $sourcePath = Join-Path -Path $source -ChildPath '/*'
    $modulepath = Join-Path -Path ./deb/automatedlab/usr/local/share/powershell/Modules -ChildPath "$($source.Name)/$($env:APPVEYOR_BUILD_VERSION)"
    $null = New-Item -ItemType Directory -Path $modulePath -Force
    Copy-Item -Path $sourcePath -Destination $modulePath -Force -Recurse
}

Save-Module -Name AutomatedLab.Common, newtonsoft.json, Ships, PSFramework, xPSDesiredStateConfiguration, xDscDiagnostics, xWebAdministration -Path ./deb/automatedlab/usr/local/share/powershell/Modules

# Pre-configure LabSources for the user
$confPath = "./deb/automatedlab/usr/local/share/powershell/Modules/AutomatedLab/$($env:APPVEYOR_BUILD_VERSION)/AutomatedLab.init.ps1"
Add-Content -Path $confPath -Value 'Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description "Location of lab sources folder" -Validation string -Value "/usr/share/AutomatedLab/LabSources"'

Copy-Item -Path ./Assets/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
Copy-Item -Path ./LabSources/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force

# Update permissions on AL folder to allow non-root access to configs
chmod -R 775 ./deb/automatedlab/usr/share/AutomatedLab

# Build debian package and convert it to RPM
dpkg-deb --build ./deb/automatedlab automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
sudo alien -r automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
Rename-Item -Path "*.rpm" -NewName automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.rpm