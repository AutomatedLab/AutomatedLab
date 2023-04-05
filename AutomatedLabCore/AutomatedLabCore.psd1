@{
    RootModule             = 'AutomatedLabCore.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '6ee6d36f-7914-4bf6-9e3b-c0131669e808'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'Automated lab environments with ease - Linux and Windows, Hyper-V and Azure'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    CLRVersion             = '4.0'

    ScriptsToProcess       = @()

    FormatsToProcess       = @('AutomatedLabCore.format.ps1xml')

    NestedModules          = @( )

    RequiredModules        = @( )

    CmdletsToExport        = @()

    FunctionsToExport      = @(
        'Install-LabScvmm',
        'Install-LabRdsCertificate',
        'Install-LabAzureRequiredModule',
        'Uninstall-LabRdsCertificate',
        'New-LabSourcesFolder',
        'Add-LabAzureSubscription',
        'Add-LabCertificate',
        'Add-LabVMUserRight',
        'Add-LabVMWareSettings',
        'Checkpoint-LabVM',
        'Clear-Lab',
        'Clear-LabCache',
        'Connect-Lab',
        'Connect-LabVM',
        'Copy-LabALCommon',
        'Copy-LabFileItem',
        'Disable-LabVMFirewallGroup',
        'Disconnect-Lab',
        'Dismount-LabIsoImage',
        'Enable-LabCertificateAutoenrollment',
        'Enable-LabHostRemoting',
        'Enable-LabVMFirewallGroup',
        'Enable-LabVMRemoting',
        'Enter-LabPSSession',
        'Export-Lab',
        'Get-Lab',
        'Get-LabAvailableOperatingSystem',
        'Get-LabAzureAppServicePlan',
        'Get-LabAzureCertificate',
        'Get-LabAzureDefaultLocation',
        'Get-LabAzureDefaultResourceGroup',
        'Get-LabAzureLabSourcesContent',
        'Get-LabAzureLabSourcesStorage',
        'Get-LabAzureLocation',
        'Get-LabAzureResourceGroup',
        'Get-LabAzureSubscription',
        'Get-LabAzureWebApp',
        'Get-LabAzureWebAppStatus',
        'Get-LabCertificate',
        'Get-LabHyperVAvailableMemory',
        'Get-LabInternetFile',
        'Get-LabIssuingCA',
        'Get-LabVMUacStatus',
        'Get-LabPSSession',
        'Get-LabSoftwarePackage',
        'Get-LabSourcesLocation',
        'Get-LabSourcesLocationInternal',
        'Get-LabVariable',
        'Get-LabVHDX',
        'Get-LabVM',
        'Get-LabVMDotNetFrameworkVersion',
        'Get-LabVMRdpFile',
        'Get-LabVMStatus',
        'Get-LabVMUptime',
        'Get-LabWindowsFeature',
        'Get-LabAzureAvailableSku',
        'Get-LabAzureAvailableRoleSize',
        'Get-LabTfsUri',
        'Import-Lab',
        'Import-LabAzureCertificate',
        'Install-Lab',
        'Install-LabADDSTrust',
        'Install-LabAdfs',
        'Install-LabAdfsProxy',
        'Install-LabAzureServices',
        'Install-LabBuildWorker',
        'Install-LabDcs',
        'Install-LabDnsForwarder',
        'Install-LabDscClient',
        'Install-LabDscPullServer',
        'Install-LabFailoverCluster',
        'Install-LabFirstChildDcs',
        'Install-LabOffice2013',
        'Install-LabOffice2016',
        'Install-LabRootDcs',
        'Install-LabRouting',
        'Install-LabSoftwarePackage',
        'Install-LabSoftwarePackages',
        'Install-LabSqlSampleDatabases',
        'Install-LabSqlServers',
        'Install-LabWindowsFeature',
        'Install-LabTeamFoundationEnvironment',
        'Install-LabHyperV',
        'Install-LabWindowsAdminCenter',
        'Install-LabScom',
        'Install-LabDynamics',
        'Install-LabRemoteDesktopServices',
        'Install-LabConfigurationManager',
        'Add-LabWacManagedNode',
        'Invoke-LabCommand',
        'Invoke-LabDscConfiguration',
        'Join-LabVMDomain',
        'Mount-LabIsoImage',
        'New-LabADSubnet',
        'New-LabAzureLabSourcesStorage',
        'New-LabAzureAppServicePlan',
        'New-LabAzureWebApp',
        'New-LabAzureRmResourceGroup',
        'New-LabCATemplate',
        'New-LabPSSession',
        'New-LabVHDX',
        'New-LabVM',
        'New-LabBaseImages',
        'Remove-LabDeploymentFiles',
        'Remove-Lab',
        'Remove-LabAzureLabSourcesStorage',
        'Remove-LabAzureResourceGroup',
        'Remove-LabDscLocalConfigurationManagerConfiguration',
        'Remove-LabPSSession',
        'Remove-LabVariable',
        'Remove-LabVM',
        'Remove-LabVMSnapshot',
        'Request-LabCertificate',
        'Reset-AutomatedLab',
        'Restart-LabVM',
        'Restart-ServiceResilient',
        'Restore-LabConnection',
        'Restore-LabVMSnapshot',
        'Save-LabVM',
        'Enable-LabAutoLogon',
        'Disable-LabAutoLogon',
        'Set-LabAzureDefaultLocation',
        'Set-LabAzureWebAppContent',
        'Set-LabDefaultOperatingSystem',
        'Set-LabDefaultVirtualizationEngine',
        'Set-LabDscLocalConfigurationManagerConfiguration',
        'Set-LabGlobalNamePrefix',
        'Set-LabInstallationCredential',
        'Set-LabVMUacStatus',
        'Show-LabDeploymentSummary',
        'Start-LabAzureWebApp',
        'Start-LabVM',
        'Stop-LabAzureWebApp',
        'Stop-LabVM',
        'Sync-LabActiveDirectory',
        'Sync-LabAzureLabSources',        
        'Test-LabADReady',
        'Test-LabAutoLogon',
        'Test-LabAzureLabSourcesStorage',
        'Test-LabCATemplate',
        'Test-LabMachineInternetConnectivity',
        'Test-LabHostRemoting',
        'Test-LabPathIsOnLabAzureLabSourcesStorage',
        'Test-LabTfsEnvironment',
        'Unblock-LabSources',
        'Undo-LabHostRemoting',
        'Uninstall-LabWindowsFeature'
        'Update-LabAzureSettings',
        'Update-LabIsoImage',
        'Update-LabBaseImage',
        'Update-LabSysinternalsTools',
        'Wait-LabADReady',
        'Wait-LabVM',
        'Wait-LabVMRestart',
        'Wait-LabVMShutdown',
        'Get-LabBuildStep',
        'Get-LabReleaseStep',
        'Get-LabCache',
        'New-LabReleasePipeline',
        'Get-LabTfsParameter',
        'Open-LabTfsSite'
        'Enable-LabTelemetry',
        'Disable-LabTelemetry',
        'Get-LabConfigurationItem',
        'Register-LabArgumentCompleters',
        'Get-LabVmSnapshot',
        'Test-LabHostConnected',
        'Test-LabAzureModuleAvailability',
        'Get-LabMachineAutoShutdown',
        'Enable-LabMachineAutoShutdown',
        'Disable-LabMAchineAutoShutdown',
        'Get-LabTfsFeed',
        'New-LabTfsFeed',
        'New-LabCimSession',
        'Get-LabCimSession',
        'Remove-LabCimSession',
        'Enable-LabInternalRouting',
        'Request-LabAzureJitAccess',
        'Enable-LabAzureJitAccess',
        'Install-LabSshKnownHost',
        'UnInstall-LabSshKnownHost',
        'Get-LabSshKnownHost',
        'Initialize-LabWindowsActivation',
        'Register-LabAzureRequiredResourceProvider'
    )

    AliasesToExport        = @(
        'Disable-LabHostRemoting',
        '??'
    )

    FileList               = @( )

    PrivateData       = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
