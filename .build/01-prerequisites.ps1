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
elseif ($IsLinux)
{
  # Ruby tool FPM can build packages for multiple distributions
  $null = sudo apt update
  #sudo apt upgrade -y
  $null = sudo apt install alien -y
}

# Resolve Module will fail since AL requests interactivity, importing module fails without LabSources folder
try { [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 0, 'Machine') } catch {}
$env:AUTOMATEDLAB_TELEMETRY_OPTIN = 0

if ($IsLinux)
{
  $null = sudo mkdir /usr/share/AutomatedLab/Assets -p
  $null = sudo mkdir /usr/share/AutomatedLab/Stores -p
  $null = sudo mkdir /usr/share/AutomatedLab/Labs -p
  $null = sudo mkdir /usr/share/AutomatedLab/LabSources -p
}

$modpath = New-Item -ItemType Directory -Force -Path (Join-Path $buildFolder requiredmodules)
Write-Host "Downloading required modules"
Save-Module -Name powershell-yaml, Pester, AutomatedLab.Common, PSFramework, xPSDesiredStateConfiguration, xDscDiagnostics, xWebAdministration, PackageManagement, PowerShellGet, PlatyPS, Ships -Repository PSGallery -Path $modpath.FullName
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = $modPath.FullName
}

Remove-Module -Name PackageManagement, PowerShellGet -Force
Import-Module -Name PackageManagement, PowerShellGet

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
