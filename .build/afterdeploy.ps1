Write-Host "'after_deploy' block"
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
$sourceLibraryPathCore = Join-Path $env:APPVEYOR_BUILD_FOLDER 'LabXml/bin/Debug/netcoreapp2.2'


if (-not (Test-Path $mainModule))
{
    robocopy /S /E $sourceLibraryPath (Split-Path $mainModule)
}
if (-not (Test-Path $mainModuleCore))
{
    robocopy /S /E $sourceLibraryPathCore (Split-Path $mainModuleCore)
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

    Start-Job -Name "Publish $m" -ScriptBlock {
        $publishParams = $args[0]
        Publish-Module @publishParams
    } -ArgumentList $publishParams | Receive-Job -AutoRemoveJob -Wait
}