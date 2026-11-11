param (
  [switch]
  $IsLocalBuild
)

git submodule -q update --init --recursive
$buildFolder = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }
Write-Host "Init task - Set version number if necessary"
if ($env:APPVEYOR_BUILD_VERSION)
{
  $currVersion = [version]$env:APPVEYOR_BUILD_VERSION
  $compareVersion = [version]::new($currVersion.Major, $currVersion.Minor, 0, 0)
  try
  {
    #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
    if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
    {
      Write-Verbose -Message 'Adding support for TLS 1.2'
      [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }
  }
  catch
  {
    Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
  }
}

# Grab nuget bits, install modules, set build variables, start build.
if (-not $IsLinux -and -not (Get-PackageProvider -Name Nuget))
{
  $null = Install-PackageProvider -Name Nuget -Force -Scope CurrentUser
}
elseif ($IsLinux -and -not $IsLocalBuild.IsPresent)
{
  # Ruby tool FPM can build packages for multiple distributions
  $null = sudo apt update
  #sudo apt upgrade -y
  $null = sudo apt install alien -y
}

# Resolve Module will fail since AL requests interactivity, importing module fails without LabSources folder
try { [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 0, 'Machine') } catch {}
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 0

if ($IsLinux -and -not $IsLocalBuild.IsPresent)
{
  $null = sudo mkdir /usr/share/AutomatedLab/Assets -p
  $null = sudo mkdir /usr/share/AutomatedLab/Stores -p
  $null = sudo mkdir /usr/share/AutomatedLab/Labs -p
  $null = sudo mkdir /usr/share/AutomatedLab/LabSources -p
}

$modpath = New-Item -ItemType Directory -Force -Path (Join-Path $buildFolder requiredmodules)
Write-Host "Downloading required modules"
# Saving a module version that already exists deletes its folder first. When a running session has one of its files loaded, that
# fails halfway and leaves a broken module behind, so only the versions that are missing are downloaded. A version counts as
# present when its manifest is there, because an empty or half-deleted version folder is exactly that broken module.
foreach ($moduleName in 'powershell-yaml', 'Pester', 'AutomatedLab.Common', 'PSFramework', 'Posh-SSH', 'xPSDesiredStateConfiguration', 'xDscDiagnostics', 'xWebAdministration', 'PackageManagement', 'PowerShellGet', 'PlatyPS', 'Ships')
{
  try
  {
    $latest = Find-Module -Name $moduleName -Repository PSGallery -ErrorAction Stop
  }
  catch
  {
    # A copy that was saved earlier still serves the build when the gallery cannot be reached; without one the build stops here.
    $saved = Get-ChildItem -Path $modpath.FullName -Recurse -File -Filter '*.psd1' -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "$moduleName.psd1" }
    if (-not $saved)
    {
      throw
    }
    Write-Warning -Message "Could not look up $moduleName in the PowerShell Gallery, so the saved copy is used. $($_.Exception.Message)"
    continue
  }

  $manifestPath = Join-Path (Join-Path (Join-Path $modpath.FullName $latest.Name) ([string]$latest.Version)) "$($latest.Name).psd1"
  if (-not (Test-Path -Path $manifestPath))
  {
    Save-Module -Name $moduleName -RequiredVersion $latest.Version -Repository PSGallery -Path $modpath.FullName
  }
}
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = "$($modPath.FullName)$sep$($env:PSModulePath)"
}

Remove-Module -Name PackageManagement, PowerShellGet -Force
Import-Module -Name PackageManagement, PowerShellGet

if ($IsLocalBuild.IsPresent) { return }

if ($env:APPVEYOR_REPO_BRANCH -eq "master" -and [string]::IsNullOrWhiteSpace($env:APPVEYOR_PULL_REQUEST_TITLE) -and $currVersion -gt $compareVersion)
{
  $properVersion = $compareVersion.ToString(3)
  Add-AppVeyorMessage -Category Warning "Resetting version from $env:APPVEYOR_BUILD_VERSION to $properVersion"
  $deleteBuild = $env:APPVEYOR_BUILD_VERSION
  [environment]::setenvironmentvariable('APPVEYOR_BUILD_VERSION', $properVersion )
  Update-AppveyorBuild -Version $properVersion

  Add-AppVeyorMessage "Calling API to reset build to 1 for next commit"
  $appveyorUrl = "https://ci.appveyor.com/api/projects/automatedlab/automatedlab/settings/build-number"

  $headers = @{
    "Authorization" = "Bearer $env:AppVeyorApi"
    "Content-type"  = "application/json"
  }

  $body = @{ nextBuildNumber = 1 }
  $body = $body | ConvertTo-Json
  Invoke-RestMethod -Uri $appveyorUrl -Headers $headers -Body $body -Method Put
}
