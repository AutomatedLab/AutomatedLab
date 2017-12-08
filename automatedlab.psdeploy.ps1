# Generic module deployment.
# This stuff should be moved to psake for a cleaner deployment view

# ASSUMPTIONS:

# folder structure of:
# - RepoFolder
#   - This PSDeploy file
#   - ModuleName
#     - ModuleName.psd1

# Nuget key in $ENV:NugetApiKey

# Set-BuildEnvironment from BuildHelpers module has populated ENV:BHProjectName

# Publish to gallery with a few restrictions
if (
    (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -and
    $env:BHBuildSystem -ne 'Unknown' -and
    $env:BHBranchName -eq "master"
)
{
    Deploy Module {
        By PSGalleryModule {
            FromSource (Join-Path $ENV:BHProjectPath $ENV:BHProjectName)
            To PSGallery
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
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
    (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -and
    $env:BHBuildSystem -eq 'AppVeyor'
)
{
    Deploy DeveloperBuild {
        By AppVeyorModule {
            FromSource (Join-Path $ENV:BHProjectPath $ENV:BHProjectName)
            To AppVeyor
            WithOptions @{
                Version = $env:APPVEYOR_BUILD_VERSION
            }
        }
    }
}
