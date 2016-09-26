@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess = 'AutomatedLab.psm1'
    
    # Version number of this module.
    ModuleVersion = '3.7.2.0'
    
    # ID used to uniquely identify this module
    GUID = '6ee6d36f-7914-4bf6-9e3b-c0131669e808'
    
    # Author of this module
    Author = 'Raimund Andree, Per Pedersen'
    
    # Company or vendor of this module
    CompanyName = 'AutomatedLab Team'
    
    # Copyright statement for this module
    Copyright = '2016'
    
    # Description of the functionality provided by this module
    Description = 'The module creates a Hyper-V visual lab automatically as defined in the XML files.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'
    
    # Name of the Windows PowerShell host required by this module
    PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    PowerShellHostVersion = ''
    
    # Minimum version of the .NET Framework required by this module
    DotNetFrameworkVersion = '4.0'
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = '4.0'
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @('AutomatedLab.init.ps1')
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('AutmatedLab.format.ps1xml')
    
    # Modules to import as nested modules of the module specified in ModuleToProcess
    NestedModules = @(
        'AutomatedLab.dll',
        'AutomatedLabADDS.psm1',
        'AutomatedLabADCS.psm1',
        'AutomatedLabDisks.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabExchange2013.psm1',
        'AutomatedLabSharePoint.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabAzure.psm1',
        'AutomatedLabVMWare.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabDsc.psm1'
    )
    
    # Functions to export from this module
    FunctionsToExport = 'Get-Lab',
        'Clear-Lab',
        'Set-LabHost',
        'Get-LabMachine',
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
        'Install-LabExchange2013Schema',
        'Install-LabExchange2013DomainPrep',
        'Install-LabExchange2013Server',
        'Install-LabExchange2013Prerequisites',
        'Install-LabSqlServers',
        'Install-LabSqlServers2008',
        'Install-LabSqlServers2012',
        'Install-LabSqlServers2014',
        'Install-LabDscPullServer',
        'Install-LabDscClient',
        'Set-LabInstallationCredential',
        'Show-LabInstallationTime',
        'Set-LabGlobalNamePrefix',
        'Wait-LabADReady',
        'Add-LabAzureSubscription',
        'Get-LabAzureSubscription',
        'Remove-LabAzureSubscription',
        'Get-LabAzureLocation',
        'Get-LabAzureDefaultLocation',
        'Set-LabAzureDefaultLocation',
        'Get-LabAzureDefaultAffinityGroup',
        'Set-LabAzureDefaultAffinityGroup',
        'Get-LabAzureDefaultStorageAccount',
        'Set-LabAzureDefaultStorageAccount',
        'Wait-LabVMRestart',
        'Get-LabVMUptime',
        'Install-LabRootDcs',
        'Install-LabFirstChildDcs',
        'Install-LabDcs',
        'Get-LabAzureDefaultService',
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
        'Add-LabAzurePublishSettingFile',
        'Invoke-LabDnsAndTrusts',
        'Get-LabVirtualNetwork',
        'Set-LabGlobalInstallationCredential',
        'Get-StringSection',
        'Get-LabInternetFile',
        'Get-FullMesh',
        'Get-NextOid',
        'Sync-Parameter',
        'Unblock-LabSources',
        'Add-VariableToPSSession',
        'Add-FunctionToPSSession',
        'Get-LabMachineUacStatus', 'Set-LabMachineUacStatus',
        'Get-LabMachineDescription', 'Set-LabMachineDescription',
        'Test-LabMachineInternetConnectivity'
    
    # List of all modules packaged with this module
    ModuleList = @(
        'AutomatedLab.psm1',
        'AutomatedLabADDS.psm1',
        'AutomatedLabADCS.psm1',
        'AutomatedLabDisks.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabExchange2013.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabAzure.psm1',
        'AutomatedLabVMWare.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabDsc.psm1'
    )
    
    # List of all files packaged with this module
    FileList = @(
        'AutmatedLab.format.ps1xml',
        'AutomatedLab.init.ps1',
        'AutomatedLab.psd1', 
        'AutomatedLab.psm1', 
        'AutomatedLabADDS.psm1',
        'AutomatedLabADCS.psm1', 
        'AutomatedLabDisks.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabExchange.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabAzure.psm1', 
        'AutomatedLabVMWare.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabDsc.psm1'
    )
    
    # Private data to pass to the module specified in ModuleToProcess
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

        DoNotUseGetHostEntryInNewLabPSSession = $false

        #Hyper-V VM Settings
        SetLocalIntranetSites = 'All' #All, Forest, Domain, None

        #Azure
        MinimumAzureModuleVersion = '0.9.3'
        DefaultAzureRoleSize = 'A'

        #Exchange
        ExchangeUcmaDownloadLink = 'http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
        Exchange2013DownloadLink = 'https://download.microsoft.com/download/7/4/9/74981C3B-0D3C-4068-8272-22358F78305F/Exchange2013-x64-cu13.exe'
        Exchange2016DownloadLink = 'https://download.microsoft.com/download/3/9/B/39B8DDA8-509C-4B9E-BCE9-4CD8CDC9A7DA/Exchange2016-x64.exe' 

        #SysInternals
        SysInternalsUrl = 'https://technet.microsoft.com/da-dk/sysinternals/bb842062'
        SysInternalsDownloadUrl = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
    }
}