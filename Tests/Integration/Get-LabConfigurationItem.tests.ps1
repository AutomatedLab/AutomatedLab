# Use settings.psd1 from build to check all settings
$rootpath = $PSScriptRoot
$configurationPath = $(Resolve-Path -Path "$rootpath\..\..\AutomatedLab\settings.psd1" -ErrorAction Stop).Path

if (-not (Get-Module -List Newtonsoft.Json)) {Install-Module -Name Newtonsoft.Json -Force -SkipPublisherCheck -AllowClobber}
if (-not (Get-Module -List powershell-yaml)) {Install-Module -Name powershell-yaml -Force -SkipPublisherCheck -AllowClobber}
if (-not (Get-Module -List Datum)) {Install-Module -Name Datum -Force -SkipPublisherCheck -AllowClobber}

Import-Module -Name Newtonsoft.Json,powershell-yaml
Import-Module -Name Datum,"$rootpath\..\..\AutomatedLab.Common\AutomatedLab.Common\AutomatedLab.Common.psd1" -Force -Verbose
[System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTOUT',0, 'Machine')
$env:AUTOMATEDLAB_TELEMETRY_OPTOUT = 0

$reqdModules = @(
    'AutomatedLabUnattended'
    'PSLog',
    'PSFileTransfer',
    'AutomatedLabDefinition',
    'AutomatedLabWorker',
    'HostsFile',
    'AutomatedLabNotifications',
    'AutomatedLab'
)
foreach ($mod in $reqdModules)
{
    Write-Host "Importing $(Resolve-Path -Path "$rootpath\..\..\$mod\$mod.psd1")"
    Import-Module -Name "$rootpath\..\..\$mod\$mod.psd1" -Force
}

Write-Host "Testing with Pester $($(Get-Module -Name Pester).Version)"

Describe 'Get-LabConfigurationItem' {
    $functionCalls = (Get-ChildItem -Path "$rootpath\..\.." -Recurse -Filter *.ps*1 | select-string -Pattern 'Get-LabConfigurationItem -Name \w+').Matches.Value | Sort-Object -Unique

    It 'Should contain all settings' {
        Get-LabConfigurationItem -GlobalPath $configurationPath | Should -Not -Be $null
    }
    

    $configuration = Get-LabConfigurationItem -GlobalPath $configurationPath

    foreach ($call in $functionCalls)
    {
        $m = $call -match '-Name\s(?<Name>\w+)'
        It "Should contain a key for setting $($Matches.Name)" {
            $configuration.Contains($Matches.Name) | Should -Be $true
        }
    }
}