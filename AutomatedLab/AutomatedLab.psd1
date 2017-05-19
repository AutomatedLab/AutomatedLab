@{
    RootModule = 'AutomatedLab.psm1'
    
    ModuleVersion = '4.1.1.0'
    
    GUID = '6ee6d36f-7914-4bf6-9e3b-c0131669e808'
    
    Author = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
    
    CompanyName = 'AutomatedLab Team'
    
    Copyright = '2016'
    
    Description = 'The module creates a Hyper-V visual lab automatically as defined in the XML files.'
    
    PowerShellVersion = '5.0'
    
    DotNetFrameworkVersion = '4.0'
    
    CLRVersion = '4.0'

	ModuleList = @('AutomatedLab')
    
    ScriptsToProcess = @('AutomatedLab.init.ps1')
    
    FormatsToProcess = @('AutomatedLab.format.ps1xml')
    
    NestedModules = @(
        'AutomatedLab.dll',
        'AutomatedLabADDS.psm1',
        'AutomatedLabADCS.psm1',
        'AutomatedLabADFS.psm1',
        'AutomatedLabDisks.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabExchange2013.psm1',
        'AutomatedLabExchange2016.psm1', 
        'AutomatedLabSharePoint.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabAzure.psm1',
        'AutomatedLabVMWare.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabDsc.psm1'
        'AutomatedLabOffice.psm1'
    )

    RequiredModules = @(
        'AutomatedLabDefinition',
        'PSLog',
        'PSFileTransfer',
        'AutomatedLabWorker',
        'HostsFile',
        'AutomatedLabUnattended'
    )
    
    # Functions to export from this module
    FunctionsToExport = @('Get-Lab',
        'Clear-Lab',
        'Set-LabHost',
        'Get-LabVM',
        'Get-LabVMStatus',
        'Get-LabSoftwarePackage',
        'Get-LabAvailableOperatingSystem',
        'Update-LabIsoImage',
        'Import-Lab',
        'Export-Lab',
        'Install-Lab',
        'Get-LabWindowsFeature',
        'Install-LabWindowsFeature',
        'Install-LabSoftwarePackage',
        'Install-LabSoftwarePackages',
        'New-LabVM',
        'Remove-LabVM',
        'Restart-LabVM',
        'Start-LabVM',
        'Wait-LabVM',
        'Stop-LabVM',
        'Save-LabVM',
        'Enable-LabVMRemoting',
        'Enable-LabHostRemoting',
        'Invoke-LabCommand',
        'Checkpoint-LabVM',
        'Remove-LabVMSnapshot',
        'Restore-LabVMSnapshot',
        'Remove-Lab',
        'Get-LabVHDX',
        'New-LabVHDX',
        'Remove-LabVHDX',
        'New-LabPSSession',
        'Remove-LabPSSession',
        'Enter-LabPSSession',
        'Get-LabPSSession',
        'New-LabADSubnet',
        'Install-LabExchange2013',
        'Install-LabExchange2016',
        'Install-LabSqlServers',
        'Install-LabSqlServers2008',
        'Install-LabSqlServers2012',
        'Install-LabSqlServers2014',
        'Install-LabOffice2013',
        'Install-LabOffice2016',
        'Install-LabDscPullServer',
        'Install-LabDscClient',
        'Install-LabRouting',
        'Install-LabAdfs',
        'Install-LabAdfsProxy',
        'Set-LabInstallationCredential',
        'Show-LabDeploymentSummary',
        'Set-LabGlobalNamePrefix',
        'Wait-LabADReady',
        'Add-LabAzureSubscription',
        'Get-LabAzureSubscription',
        'Remove-LabAzureSubscription',
        'Get-LabAzureLocation',
        'Get-LabAzureDefaultLocation',
        'Set-LabAzureDefaultLocation',
        'Get-LabAzureDefaultStorageAccount',
        'Set-LabAzureDefaultStorageAccount',
        'Get-LabAzureResourceGroup',
        'Update-LabAzureSettings',
        'Wait-LabVMRestart',
        'Get-LabVMUptime',
        'Install-LabRootDcs',
        'Install-LabFirstChildDcs',
        'Install-LabDcs',
        'Get-LabAzureDefaultResourceGroup',
        'Import-LabAzureCertificate',
        'Get-LabAzureCertificate',
        'Get-LabIssuingCA',
        'Request-LabCertificate',
        'Get-LabCertificatePfx',
        'Add-LabCertificatePfx',
        'Connect-LabVM',
        'Wait-LabVMShutdown',
        'Add-LabVMWareSettings',
        'Get-LabVMRdpFile',
        'Set-LabToolsPath',
        'Set-LabDefaultOperatingSystem',
        'Set-LabDefaultVirtualizationEngine',
        'Set-LabGlobalNamePrefix',
        'Get-LabSourcesLocation',
        'Get-LabSourcesLocationInternal',
        'Get-LabVariable',
        'Remove-LabVariable',
        '*-LabAzureService',
        'Join-LabVMDomain',
        'Clear-LabCache',
        'Get-LabHyperVAvailableMemory',
        'Enable-ProgressIndicator',
        'Disable-ProgressIndicator',
        'Write-ProgressIndicator',
        'Write-ProgressIndicatorEnd',
        'Reset-AutomatedLab',
        'Write-ScreenInfo',
        'Enable-LabCertificateAutoenrollment',
        'New-LabCATemplate',
        'Test-LabCATemplate',
        'Add-LabVMUserRight',
        'Save-Hashes',
        'Test-FileList',
        'Test-FileHashes',
        'Restart-ServiceResilient',
        'Mount-LabIsoImage','Dismount-LabIsoImage',
        'Set-LabLocalVirtualMachineDiskAuto',
        'Get-LabAzureNearestLocation',
        'Test-FolderExist',
        'Test-FolderNotExist',
        'Sync-LabActiveDirectory',
        'Remove-DeploymentFiles',
        'Enable-LabVMFirewallGroup',
        'Disable-LabVMFirewallGroup',
        'Dismount-LabIsoImage',
        'Test-Port',
        'Install-LabDnsForwarder',
        'Install-LabADDSTrust',
        'Get-LabVirtualNetwork',
        'Set-LabGlobalInstallationCredential',
        'Get-StringSection',
        'Add-StringIncrement',
        'Get-LabInternetFile',
        'Get-FullMesh',
        'Get-NextOid',
        'Sync-Parameter',
        'Unblock-LabSources',
        'Add-VariableToPSSession',
        'Add-FunctionToPSSession',
        'Get-LabMachineUacStatus', 'Set-LabMachineUacStatus',
        'Get-LabMachineDescription', 'Set-LabMachineDescription',
        'Test-LabMachineInternetConnectivity',
        'Add-LabAzureProfile',
        'New-LabAzureLabSourcesStorage',
        'Get-LabAzureLabSourcesStorage',
        'Remove-LabAzureLabSourcesStorage',
        'Test-LabAzureLabSourcesStorage',
        'Sync-LabAzureLabSources',
        'Test-LabSourcesOnAzureStorage',
        'Test-LabPathIsOnLabAzureLabSourcesStorage',
        'Remove-LabAzureResourceGroup',
        'Get-LabAzureLabSourcesContent'
    )
    
    # List of all files packaged with this module
    FileList = @(
        'AutomatedLab.format.ps1xml',
        'AutomatedLab.init.ps1',
        'AutomatedLab.psd1', 
        'AutomatedLab.psm1', 
        'AutomatedLabADDS.psm1',
        'AutomatedLabADCS.psm1', 
        'AutomatedLabDisks.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabExchange2013.psm1',
        'AutomatedLabExchange2016.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabAzure.psm1', 
        'AutomatedLabVMWare.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabDsc.psm1',
        'AutomatedLabOffice.psm1'
    )
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        #Timeouts
        Timeout_WaitLabMachine_Online = 60
        Timeout_StartLabMachine_Online = 60
        Timeout_RestartLabMachine_Shutdown = 30
        Timeout_StopLabMachine_Shutdown = 30
        
        Timeout_InstallLabCAInstallation = 40
        
        Timeout_DcPromotionRestartAfterDcpromo = 60
        Timeout_DcPromotionAdwsReady = 20
        
        Timeout_Sql2008Installation = 90
        Timeout_Sql2012Installation = 90
        Timeout_Sql2014Installation = 90

        Timeout_VisualStudio2013Installation = 90
        Timeout_VisualStudio2015Installation = 90

        InvokeLabCommandRetries = 3
        InvokeLabCommandRetryIntervalInSeconds = 10

        DoNotUseGetHostEntryInNewLabPSSession = $true

        #General VM settings
        DisableWindowsDefender = $true

        #Hyper-V VM Settings
        SetLocalIntranetSites = 'All' #All, Forest, Domain, None

        #Azure
        MinimumAzureModuleVersion = '4.0.0'
        DefaultAzureRoleSize = 'A'

        #Exchange
        ExchangeUcmaDownloadLink = 'http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
        Exchange2013DownloadLink = 'https://download.microsoft.com/download/7/B/9/7B91E07E-21D6-407E-803B-85236C04D25D/Exchange2013-x64-cu16.exe'
        #Exchange2016DownloadLink = 'https://download.microsoft.com/download/3/9/B/39B8DDA8-509C-4B9E-BCE9-4CD8CDC9A7DA/Exchange2016-x64.exe' the Exchange CUs are ISOs again

        #Office
        OfficeDeploymentTool = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_7614-3602.exe'

        #SysInternals
        SysInternalsUrl = 'https://technet.microsoft.com/en-us/sysinternals/bb842062'
        SysInternalsDownloadUrl = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'

        #.net Framework
        dotnet452DownloadLink = 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
        dotnet46DownloadLink = 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe'
        dotnet462DownloadLink = 'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe'

        #SQL Server 2016 Management Studio
        Sql2016ManagementStudio = 'https://go.microsoft.com/fwlink/?LinkID=840946'
    }
}