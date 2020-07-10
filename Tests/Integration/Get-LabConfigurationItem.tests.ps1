# Use settings.psd1 from build to check all settings
return # skipping tests for now

$rootpath = $PSScriptRoot

if (-not (Get-Module -List AutomatedLab.Common)) {Install-Module -Name AutomatedLab.Common -Force -SkipPublisherCheck -AllowClobber}
if (-not (Get-Module -List PSFramework)) {Install-Module -Name PSFramework -Force -SkipPublisherCheck -AllowClobber}

Import-Module -Name PSFramework, AutomatedLab.Common
Import-Module -Name Pester
if (-not $env:AUTOMATEDLAB_TELEMETRY_OPTOUT)
{
    [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTOUT',0, 'Machine')
    $env:AUTOMATEDLAB_TELEMETRY_OPTOUT = 0
}

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
    $functionCalls = (Get-ChildItem -Path "$rootpath\..\.." -Recurse -Filter *.ps*1 | select-string -Pattern 'Get-LabConfigurationItem -Name [\w\.-]+').Matches.Value | Sort-Object -Unique

    It 'Should contain all settings' {
        Get-LabConfigurationItem  | Should -Not -Be $null
    }

    foreach ($call in $functionCalls)
    {
        $m = $call -match '-Name\s(?<Name>[\w\.-]+)'
        $n = $Matches.Name
        It "Should contain a key for setting $n" {
            Get-LabConfigurationItem -Name $n | Should -Not -Be $null
        }
    }
}