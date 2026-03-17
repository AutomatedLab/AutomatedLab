param (
    [switch]
    $BuildInstaller,

    [switch]
    $SkipValidation
)

Push-Location
Set-Location -Path $PSScriptRoot
./01-prerequisites.ps1 -IsLocalBuild
./02-build.ps1 -IsLocalBuild -SkipInstaller:(-not $BuildInstaller.IsPresent)
if (-not $SkipValidation.IsPresent) {
    ./03-validate.ps1 -IsLocalBuild
}

Pop-Location

Get-Item (Join-Path $psscriptroot ../publish), (Join-Path $psscriptroot ../requiredmodules)
