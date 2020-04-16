Write-Host "Calling build script"
./Build.ps1
Write-Host "'after_build' block"
$Params = @{
    Path    = $env:APPVEYOR_BUILD_FOLDER
    Force   = $true
    Recurse = $false
    Verbose = $true
}
Invoke-PSDeploy @Params # Create nuget package artifacts
Write-Host "Locating installer to push as artifact"

Add-AppveyorMessage "Locating installer to push as artifact" -Category Information
$msifile = Get-ChildItem -Recurse -Filter AutomatedLab.msi | Select-Object -First 1
Push-AppVeyorArtifact $msifile.FullName -FileName $msifile.Name -DeploymentName alinstaller

Add-AppveyorMessage "Locating debian package to push as artifact" -Category Information
$debFile = Get-ChildItem -Recurse -Filter automatedlab.deb | Select-Object -First 1
Push-AppVeyorArtifact $debFile.FullName -FileName $debFile.Name -DeploymentName aldebianpackage