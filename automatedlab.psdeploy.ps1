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
    "Skipping deployment: To deploy, ensure that...`n" +
    "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* Module path is valid (Current: $(Join-Path $ENV:BHProjectPath $ENV:BHProjectName))" |
        Write-Host
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
