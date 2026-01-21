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
        'Add-LabAzureSubscription',
        'Add-LabCertificate',
        'Add-LabVMUserRight',
        'Add-LabVMWareSettings',
        'Add-LabWacManagedNode',
        'Checkpoint-LabVM',
        'Clear-Lab',
        'Clear-LabCache',
        'Connect-Lab',
        'Connect-LabProxmoxCluster',
        'Connect-LabVM',
        'Copy-LabALCommon',
        'Copy-LabFileItem',
        'Disable-LabAutoLogon',
        'Disable-LabMAchineAutoShutdown',
        'Disable-LabTelemetry',
        'Disable-LabVMFirewallGroup',
        'Disconnect-Lab',
        'Dismount-LabIsoImage',
        'Enable-LabAutoLogon',
        'Enable-LabAzureJitAccess',
        'Enable-LabCertificateAutoenrollment',
        'Enable-LabHostRemoting',
        'Enable-LabInternalRouting',
        'Enable-LabMachineAutoShutdown',
        'Enable-LabTelemetry',
        'Enable-LabVMFirewallGroup',
        'Enable-LabVMRemoting',
        'Enter-LabPSSession',
        'Export-Lab',
        'Get-Lab',
        'Get-LabAvailableOperatingSystem',
        'Get-LabAzureAppServicePlan',
        'Get-LabAzureAvailableRoleSize',
        'Get-LabAzureAvailableSku',
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
        'Get-LabBuildStep',
        'Get-LabCache',
        'Get-LabCertificate',
        'Get-LabCimSession',
        'Get-LabConfigurationItem',
        'Get-LabHyperVAvailableMemory',
        'Get-LabInternetFile',
        'Get-LabIsoImage',
        'Get-LabIssuingCA',
        'Get-LabMachineAutoShutdown',
        'Get-LabPSSession',
        'Get-LWProxmoxNode',
        'Get-LabReleaseStep',
        'Get-LabSoftwarePackage',
        'Get-LabSourcesLocation',
        'Get-LabSourcesLocationInternal',
        'Get-LabSshKnownHost',
        'Get-LabTfsFeed',
        'Get-LabTfsParameter',
        'Get-LabTfsUri',
        'Get-LabVariable',
        'Get-LabVHDX',
        'Get-LabVM',
        'Get-LabVMDotNetFrameworkVersion',
        'Get-LabVMRdpFile',
        'Get-LabVMStatus',
        'Get-LabVMUacStatus',
        'Get-LabVMUptime',
        'Get-LabVmSnapshot',
        'Get-LabWindowsFeature',
        'Import-Lab',
        'Import-LabAzureCertificate',
        'Initialize-LabWindowsActivation',
        'Install-Lab',
        'Install-LabADDSTrust',
        'Install-LabAdfs',
        'Install-LabAdfsProxy',
        'Install-LabAzureRequiredModule',
        'Install-LabAzureServices',
        'Install-LabBuildWorker',
        'Install-LabConfigurationManager',
        'Install-LabDcs',
        'Install-LabDnsForwarder',
        'Install-LabDscClient',
        'Install-LabDscPullServer',
        'Install-LabDynamics',
        'Install-LabFailoverCluster',
        'Install-LabFirstChildDcs',
        'Install-LabHyperV',
        'Install-LabOffice2013',
        'Install-LabOffice2016',
        'Install-LabRdsCertificate',
        'Install-LabRemoteDesktopServices',
        'Install-LabRootDcs',
        'Install-LabRouting',
        'Install-LabScom',
        'Install-LabScvmm',
        'Install-LabSoftwarePackage',
        'Install-LabSoftwarePackages',
        'Install-LabSqlSampleDatabases',
        'Install-LabSqlServers',
        'Install-LabSshKnownHost',
        'Install-LabTeamFoundationEnvironment',
        'Install-LabWindowsAdminCenter',
        'Install-LabWindowsFeature',
        'Invoke-LabCommand',
        'Invoke-LabDscConfiguration',
        'Join-LabVMDomain',
        'Mount-LabIsoImage',
        'New-LabADSubnet',
        'New-LabAzureAppServicePlan',
        'New-LabAzureLabSourcesStorage',
        'New-LabAzureRmResourceGroup',
        'New-LabAzureWebApp',
        'New-LabBaseImages',
        'New-LabCATemplate',
        'New-LabCimSession',
        'New-LabPSSession',
        'New-LabReleasePipeline',
        'New-LabSourcesFolder',
        'New-LabTfsFeed',
        'New-LabVHDX',
        'New-LabVM',
        'Open-LabTfsSite',
        'Register-LabArgumentCompleters',
        'Register-LabAzureRequiredResourceProvider',
        'Remove-Lab',
        'Remove-LabAzureLabSourcesStorage',
        'Remove-LabAzureResourceGroup',
        'Remove-LabCimSession',
        'Remove-LabDeploymentFiles',
        'Remove-LabDscLocalConfigurationManagerConfiguration',
        'Remove-LabPSSession',
        'Remove-LabVariable',
        'Remove-LabVM',
        'Remove-LabVMSnapshot',
        'Request-LabAzureJitAccess',
        'Request-LabCertificate',
        'Reset-AutomatedLab',
        'Restart-LabVM',
        'Restart-ServiceResilient',
        'Restore-LabConnection',
        'Restore-LabVMSnapshot',
        'Save-LabVM',
        'Select-LabProxmoxNode.ps1',
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
        'Test-LabAzureModuleAvailability',
        'Test-LabCATemplate',
        'Test-LabHostConnected',
        'Test-LabHostRemoting',
        'Test-LabMachineInternetConnectivity',
        'Test-LabPathIsOnLabAzureLabSourcesStorage',
        'Test-LabProxmoxConnection',
        'Test-LabTfsEnvironment',
        'Unblock-LabSources',
        'Undo-LabHostRemoting',
        'UnInstall-LabSshKnownHost',
        'Uninstall-LabRdsCertificate',
        'Uninstall-LabWindowsFeature',
        'Update-LabAzureSettings',
        'Update-LabBaseImage',
        'Update-LabIsoImage',
        'Update-LabSysinternalsTools',
        'Wait-LabADReady',
        'Wait-LabVM',
        'Wait-LabVMRestart',
        'Wait-LabVMShutdown'
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
