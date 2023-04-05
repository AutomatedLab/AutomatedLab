$moduleNames = @(
    'AutomatedLab'
    'AutomatedLabDefinition'
    'AutomatedLabNotifications'
    'AutomatedLab.Ships'
    'AutomatedLabTest'
    'AutomatedLabUnattended'
    'AutomatedLabWorker'
    'HostsFile'
    'PSLog'
)

# Publish to AppVeyor if we're in AppVeyor
if ($env:APPVEYOR_BUILD_VERSION)
{
    $buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }
    $modPath = Get-Item -Path (Join-Path $buildFolder publish)
    foreach ($moduleName in $moduleNames)
    {
        Write-Host "Deploying $moduleName with PSDeploy"
        Deploy DeveloperBuild {
            By AppVeyorModule {
                FromSource (Join-Path $modPath "$moduleName/*" -Resolve)
                To AppVeyor
                WithOptions @{
                    Version = $env:APPVEYOR_BUILD_VERSION
                }
            }
        }
    }
}
