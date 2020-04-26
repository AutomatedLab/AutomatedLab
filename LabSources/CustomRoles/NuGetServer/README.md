# NuGet Server

This custom role can be used to deploy NuGet server from scratch. The server binaries will be compiled 
locally on your system and pushed to your lab machine, including all preseeded packages you selected

## Usage

``` PowerShell
$role = Get-LabPostInstallationActivity -CustomRole NuGetServer -Properties @{
    Package = 'AutomatedLab','VoiceCommands', 'TelemetryHelper' # Mandatory
    PackagePath = 'C:\PackageTemp' # Optional - if Packages is not used, define a directory containing nuget files to publish
    SourceRepositoryName = 'PSGallery' # Optional - if you want to download your packages from a different upstream gallery
    ApiKey = 'MySecureApiKey' # Optional - defaults to lab installation password, e.g. Somepass1
    Port = '8080' # Optional - defaults to 80 if no CA is present or 443, if a CA is present in the lab
    UseSsl = 'true' # Optional - use only if a CA is present in the lab
}
Add-LabMachineDefinition -Name NUG01 -Memory 2GB -Roles WebServer -PostInstallationActivity $role
```

## Deployment Details

Requirements:
- Local client needs to be connected to the internet, needs access to a gallery or needs to configure a folder containing nuget packages

This custom role will:
- Compile NuGet server and download all required packages on your system
- Push the packages to your VM
- Optionally enroll for a WebServer certificate
- Deploy a new web app in IIS
- Run a little Pester test to validate the gallery actually works
- Output the gallery URI