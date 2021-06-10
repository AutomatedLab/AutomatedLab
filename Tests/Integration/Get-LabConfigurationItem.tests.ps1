BeforeDiscovery {
    $rootpath = $PSScriptRoot

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

    $functionCalls = (Get-ChildItem -Path "$rootpath\..\.." -Recurse -Filter *.ps*1 | Select-String -Pattern 'Get-LabConfigurationItem -Name [\w\.-]+').Matches.Value | Sort-Object -Unique
    
    # LabSourcesLocation and VmPath are user-defined and just pre-initialized with $null
    $skippedCalls = @('Sql', 'LabSourcesLocation', 'VmPath')
    $testCases = foreach ($call in $functionCalls)
    {
        if ($call -notmatch '-Name\s(?<Name>[\w\.-]+)') { continue }
        if ($Matches.Name -in $skippedCalls) { continue }

        @{
            Name = $Matches.Name 
            Call = $call
        }
        
    }
}

Describe 'Get-LabConfigurationItem' {
    

    It 'Should contain all settings' {
        Get-LabConfigurationItem | Should -Not -Be $null
    }

    It "Should contain a key for setting <Name>" -TestCases $testCases {
        Get-LabConfigurationItem -Name $Name | Should -Not -BeNullOrEmpty -Because "Function '$Call' uses this item"
    }
}