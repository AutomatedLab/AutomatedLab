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
    foreach ($moduleName in $moduleNames)
    {
        Deploy DeveloperBuild {
            By AppVeyorModule {
                FromSource (Join-Path $env:APPVEYOR_BUILD_FOLDER $moduleName)
                To AppVeyor
                WithOptions @{
                    Version = $env:APPVEYOR_BUILD_VERSION
                }
            }
        }
    }
}
