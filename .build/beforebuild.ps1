Write-Host "Publishing AutomatedLab library"
$projPath = Join-Path $env:APPVEYOR_BUILD_FOLDER -ChildPath 'LabXml/LabXml.csproj' -Resolve -ErrorAction Stop
$null = nuget restore
$null = dotnet publish $projPath -f net6.0 -o (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/core')
if (-not $IsLinux)
{
    $null = dotnet publish $projPath -f net462 -o (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/lib/full')
}

Write-Host "'before_build' block"
Copy-Item -Path (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'Assets/ProductKeys.xml') -Destination (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER 'AutomatedLab/ProductKeys.xml')

Write-Host "Setting version number in files"
Add-AppveyorMessage -Message "Setting version number in files" -Category Information
foreach ($item in Get-ChildItem -Filter *.psd1 -Recurse)
{
    if ($item.BaseName -notin 'AutomatedLab','AutomatedLab.Recipe','AutomatedLab.Ships','AutomatedLabDefinition','AutomatedLabNotifications','AutomatedLabTest','AutomatedLabUnattended','AutomatedLabWorker','HostsFile','PSLog','PSFileTransfer') { continue }
    if ($item.Directory.Name -eq $item.BaseName)
    {
        Add-AppveyorMessage -Message "$($item.BaseName) - $env:APPVEYOR_BUILD_VERSION, Prerelease: $($env:APPVEYOR_REPO_BRANCH -ne "master")" -Category Information
        $content = Get-Content $item.FullName
        $content = $content -replace "^\s*ModuleVersion += '\d\.\d\.\d'", "ModuleVersion = '$env:APPVEYOR_BUILD_VERSION'"
        if ($env:APPVEYOR_REPO_BRANCH -ne "master") {$content = $content -replace "Prerelease\s+=\s+''", "Prerelease = 'preview'"}
        $content | Set-Content -Path $item.FullName
    }
}

# Call all child build scripts
Write-Host "Building child modules"
$sep = if ($IsLinux) { ':' } else { ';' }
$env:PSModulePath = "$env:APPVEYOR_BUILD_FOLDER$sep$env:PSModulePath"
$modulesToBuild = 'AutomatedLab.Recipe', 'AutomatedLabNotifications', 'AutomatedLabUnattended'
foreach ($child in (Get-ChildItem -Directory -Path $env:APPVEYOR_BUILD_FOLDER | Where-Object Name -in $modulesToBuild))
{
    Write-Host -ForegroundColor DarkMagenta "Building $($child.Name)"
    & (Join-Path -Path $child.FullName -ChildPath '.build/build.ps1')
}
