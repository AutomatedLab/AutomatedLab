$moduleNames = @(
    'AutomatedLab'
    'AutomatedLabDefinition'
    'AutomatedLabNotifications'
    'AutomatedLabTest'
    'AutomatedLabUnattended'
    'AutomatedLabWorker'
    'HostsFile'
    'PSLog'
)

# Publish to gallery with a few restrictions
if ($env:APPVEYOR_REPO_BRANCH -eq "master"
)
{
    foreach ($moduleName in $moduleNames)
    {
        Deploy Module {
            By PSGalleryModule {
                FromSource (Join-Path $PSScriptRoot $moduleName)
                To PSGallery
                WithOptions @{
                    ApiKey = $ENV:NugetApiKey
                }
            }
        }
    }
}
else
{
    Write-Host "Skipping PSGallery deployment. We are in branch $env:APPVEYOR_REPO_BRANCH (PSGallery only on master)"
}

# Publish to AppVeyor if we're in AppVeyor
if (
    $env:APPVEYOR_BUILD_VERSION
)
{
    foreach ($moduleName in $moduleNames)
    {
    Deploy DeveloperBuild {
        By AppVeyorModule {
            FromSource (Join-Path $PSScriptRoot $moduleName)
            To AppVeyor
            WithOptions @{
                Version = $env:APPVEYOR_BUILD_VERSION
            }
        }
    }
}
}
