Write-Host "Calling build script"
& (Join-Path -Path $env:APPVEYOR_BUILD_FOLDER './.build/Build.ps1')
Write-Host "'after_build' block"

if (-not $IsLinux)
{
    $Params = @{
        Path    = Join-Path $env:APPVEYOR_BUILD_FOLDER -ChildPath '.build'
        Force   = $true
        Recurse = $false
        Verbose = $true
    }
    Invoke-PSDeploy @Params # Create nuget package artifacts on Windows only, we only need one set
    Add-AppveyorMessage "Locating installer to push as artifact" -Category Information
    $msifile = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse -Filter AutomatedLab.msi | Select-Object -First 1
    Push-AppVeyorArtifact $msifile.FullName -FileName $msifile.Name -DeploymentName alinstaller
}

if ($IsLinux)
{
    Add-AppveyorMessage "Locating deb package to push as artifact" -Category Information
    $debFile = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse -Filter automatedlab*.deb | Select-Object -First 1
    Push-AppVeyorArtifact $debFile.FullName -FileName $debFile.Name -DeploymentName aldebianpackage

    Add-AppveyorMessage "Locating rpm package to push as artifact" -Category Information
    $debFile = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse -Filter automatedlab*.rpm | Select-Object -First 1
    Push-AppVeyorArtifact $debFile.FullName -FileName $debFile.Name -DeploymentName alrpmpackage
}
