BeforeDiscovery {
    $rootpath = $PSScriptRoot

    if (-not (Get-Module -List AutomatedLab.Common)) { Install-Module -Name AutomatedLab.Common -Force -SkipPublisherCheck -AllowClobber }
    if (-not (Get-Module -List PSFramework)) { Install-Module -Name PSFramework -Force -SkipPublisherCheck -AllowClobber }
    if (-not (Get-Module -List powershell-yaml)) { Install-Module -Name powershell-yaml -Force -SkipPublisherCheck -AllowClobber }
    
    Import-Module -Name PSFramework, AutomatedLab.Common

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
        'AutomatedLabCore'
    )
    
    $oldPath = $env:PSModulePath
    $env:PSModulePath = '{0};{1}' -f (Resolve-Path -Path "$rootpath\..\..\publish").Path, $env:PSModulePath

    $modPath = Get-Item -Path (Resolve-Path -Path "$rootpath\..\..\requiredmodules").Path
    if (-not $env:PSModulePath.Contains($modpath.FullName))
    {
        $sep = [io.path]::PathSeparator
        $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName, $sep, $env:PSModulePath
    }

    $modPath = Get-Item -Path (Resolve-Path -Path "$rootpath\..\..\publish").Path
    if (-not $env:PSModulePath.Contains($modpath.FullName))
    {
        $sep = [io.path]::PathSeparator
        $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName, $sep, $env:PSModulePath
    }

    foreach ($mod in $reqdModules)
    {
        Import-Module -Name $mod -Force -ErrorAction SilentlyContinue
    }

    $functionCalls = (Get-ChildItem -Path "$rootpath\..\.." -Recurse -Filter *.ps*1 | Select-String -Pattern 'Get-LabConfigurationItem -Name [\w\.-]+').Matches.Value | Sort-Object -Unique
    
    # LabSourcesLocation and VmPath are user-defined and just pre-initialized with $null
    $skippedCalls = @('Sql', 'LabSourcesLocation', 'VmPath', 'AzureJitTimestamp', 'DisableVersionCheck')
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