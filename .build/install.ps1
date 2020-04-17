git submodule -q update --init --recursive

Write-Host "Init task - Set version number if necessary"
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

if (-not $IsLinux)
{
  Install-PackageProvider -Name Nuget -Force
}
else
{
  # Ruby tool FPM can build packages for multiple distributions
  sudo apt install alien -y
}
Install-Module PSFramework -Repo PSGallery -Force

if ($env:APPVEYOR_REPO_BRANCH -eq "master" -and $currVersion -gt $compareVersion)
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
