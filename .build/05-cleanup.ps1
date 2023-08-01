$buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }

$modPath = Join-Path $buildFolder requiredmodules
$publishPath = Join-Path $buildFolder publish
$nugetpath = Join-Path -Path $buildFolder -ChildPath nugets

if (Test-Path $modPath) { Remove-Item -Recurse -Force -Path $modPath -ErrorAction SilentlyContinue}
if (Test-Path $publishPath) { Remove-Item -Recurse -Force -Path $publishPath -ErrorAction SilentlyContinue}
if (Test-Path $nugetpath) { Remove-Item -Recurse -Force -Path $nugetpath -ErrorAction SilentlyContinue}
$env:PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
