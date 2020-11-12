# Use settings.psd1 from build to check all settings
$rootpath = $PSScriptRoot

Write-Host "Testing with Pester $($(Get-Module -Name Pester).Version)"

Describe 'Get-LabConfigurationItem' {
    $functionCalls = (Get-ChildItem -Path "$rootpath\..\.." -Recurse -Filter *.ps*1 | Select-String -Pattern 'Get-LabConfigurationItem -Name [\w\.-]+').Matches.Value | Sort-Object -Unique

    It 'Should contain all settings' {
        Get-LabConfigurationItem | Should -Not -Be $null
    }

    BeforeAll {
        if (-not (Get-Module -List AutomatedLab.Common)) { Install-Module -Name AutomatedLab.Common -Force -SkipPublisherCheck -AllowClobber }
        if (-not (Get-Module -List PSFramework)) { Install-Module -Name PSFramework -Force -SkipPublisherCheck -AllowClobber }
        
        Import-Module -Name PSFramework, AutomatedLab.Common
        Import-Module -Name Pester
        if (-not $env:AUTOMATEDLAB_TELEMETRY_OPTIN)
        {
            [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'no', 'Machine')
            $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'no'
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
            Import-Module -Name "$rootpath\..\..\$mod\$mod.psd1" -Force -ErrorAction SilentlyContinue
        }
    }

    # CI sql skipped -> Appears in (Get-LabConfigurationItem -Name Sql$($server.SqlVersion)SSRS)
    $skippedCalls = @('Sql')
    foreach ($call in $functionCalls)
    {
        $m = $call -match '-Name\s(?<Name>[\w\.-]+)'
        $n = $Matches.Name
        It "Should contain a key for setting $n" -TestCases @{Name = $n; Call = $call } -Skip:($n -in $skippedCalls) {
            Get-LabConfigurationItem -Name $Name | Should -Not -BeNullOrEmpty -Because "Function $call uses this item"
        }
    }
}