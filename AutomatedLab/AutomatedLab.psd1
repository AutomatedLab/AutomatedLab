@{
    RootModule             = 'AutomatedLab.psm1'
    
    ModuleVersion          = '4.5.7.0'
    
    GUID                   = '6ee6d36f-7914-4bf6-9e3b-c0131669e808'
    
    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
    
    CompanyName            = 'AutomatedLab Team'
    
    Copyright              = '2018'
    
    Description            = 'The module creates a Hyper-V visual lab automatically as defined in the XML files.'
    
    PowerShellVersion      = '5.0'
    
    DotNetFrameworkVersion = '4.0'
    
    CLRVersion             = '4.0'

    ModuleList             = @('AutomatedLab')
    
    ScriptsToProcess       = @('AutomatedLab.init.ps1')
    
    FormatsToProcess       = @('AutomatedLab.format.ps1xml')
    
    NestedModules          = @(
        'AutomatedLabAzureServices.psm1',
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
        'AutomatedLabDsc.psm1',
        'AutomatedLabOffice.psm1',
        'AutomatedLabHybrid.psm1',
        'AutomatedLabFailover.psm1',
        'AutomatedLabTfs.psm1'
    )

    RequiredModules        = @(
        'AutomatedLabDefinition',
        'PSLog',
        'PSFileTransfer',
        'AutomatedLabWorker',
        'HostsFile',
        'AutomatedLabUnattended',
        'AutomatedLabNotifications',
        'AutomatedLab.Common'
    )

    CmdletsToExport        = @()
    
    FunctionsToExport      = @(
        'New-LabSourcesFolder',
        'Add-LabAzureProfile',
        'Add-LabAzureSubscription',
        'Add-LabCertificate',
        'Add-LabVMUserRight',
        'Add-LabVMWareSettings',
        'Checkpoint-LabVM',
        'Clear-Lab',
        'Clear-LabCache',
        'Connect-Lab',
        'Connect-LabVM',
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
        'Get-LabAzureDefaultStorageAccount',
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
        'Get-LabMachineUacStatus',
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
        'Import-Lab',
        'Import-LabAzureCertificate',
        'Install-Lab',
        'Install-LabADDSTrust',
        'Install-LabAdfs',
        'Install-LabAdfsProxy',
        'Install-LabAzureServices',
        'Install-LabDcs',
        'Install-LabDnsForwarder',
        'Install-LabDscClient',
        'Install-LabDscPullServer',
        'Install-LabExchange2013',
        'Install-LabExchange2016',
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
        'Remove-DeploymentFiles',
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
        'Save-Hashes',
        'Save-LabVM',
        'Set-LabAutoLogon',
        'Set-LabAzureDefaultLocation',
        'Set-LabAzureDefaultStorageAccount',
        'Set-LabAzureWebAppContent',
        'Set-LabDefaultOperatingSystem',
        'Set-LabDefaultVirtualizationEngine',
        'Set-LabDscLocalConfigurationManagerConfiguration',
        'Set-LabGlobalNamePrefix',
        'Set-LabInstallationCredential',
        'Set-LabMachineUacStatus',
        'Show-LabDeploymentSummary',
        'Start-LabAzureWebApp',
        'Start-LabVM',
        'Stop-LabAzureWebApp',
        'Stop-LabVM',
        'Sync-LabActiveDirectory',
        'Sync-LabAzureLabSources',
        'Test-FileHashes',
        'Test-FileList',
        'Test-FolderExist',
        'Test-FolderNotExist',
        'Test-LabAutoLogon',
        'Test-LabAzureLabSourcesStorage',
        'Test-LabCATemplate',
        'Test-LabMachineInternetConnectivity',
        'Test-LabPathIsOnLabAzureLabSourcesStorage',
        'Unblock-LabSources',
        'Update-LabAzureSettings',
        'Update-LabIsoImage',
        'Update-LabBaseImage',
        'Wait-LabADReady',
        'Wait-LabVM',
        'Wait-LabVMRestart',
        'Wait-LabVMShutdown',
        'Get-LabBuildStep',
        'Get-LabReleaseStep',
        'New-LabReleasePipeline'
    )
    
    FileList               = @(
        'AutomatedLab.format.ps1xml',
        'AutomatedLab.init.ps1',
        'AutomatedLab.psd1', 
        'AutomatedLab.psm1',
        'AutomatedLabADCS.psm1',
        'AutomatedLabADDS.psm1',
        'AutomatedLabADFS.psm1',
        'AutomatedLabAzure.psm1',
        'AutomatedLabAzureServices.psm1',
        'AutomatedLabDisks.psm1',
        'AutomatedLabDsc.psm1',
        'AutomatedLabExchange2013.psm1',
        'AutomatedLabExchange2016.psm1',
        'AutomatedLabFailover.psm1',
        'AutomatedLabHybrid.psm1',
        'AutomatedLabInternals.psm1',
        'AutomatedLabNetwork.psm1',
        'AutomatedLabOffice.psm1',
        'AutomatedLabRouting.psm1',
        'AutomatedLabSharePoint.psm1',
        'AutomatedLabSQL.psm1',
        'AutomatedLabVirtualMachines.psm1',
        'AutomatedLabVMWare.psm1'
    )
    
    PrivateData            = @{
        #Timeouts
        Timeout_WaitLabMachine_Online          = 60
        Timeout_StartLabMachine_Online         = 60
        Timeout_RestartLabMachine_Shutdown     = 30
        Timeout_StopLabMachine_Shutdown        = 30
        
        Timeout_InstallLabCAInstallation       = 40
        
        Timeout_DcPromotionRestartAfterDcpromo = 60
        Timeout_DcPromotionAdwsReady           = 20
        
        Timeout_Sql2008Installation            = 90
        Timeout_Sql2012Installation            = 90
        Timeout_Sql2014Installation            = 90

        Timeout_VisualStudio2013Installation   = 90
        Timeout_VisualStudio2015Installation   = 90

        #PSSession settings
        InvokeLabCommandRetries                = 3
        InvokeLabCommandRetryIntervalInSeconds = 10
        MaxPSSessionsPerVM                     = 5
        DoNotUseGetHostEntryInNewLabPSSession  = $true

        #DSC
        DscMofPath                             = '"$labSources\DscConfigurations"'

        #General VM settings
        DisableWindowsDefender                 = $true
        DoNotSkipNonNonEnglishIso              = $false

        #Hyper-V VM Settings
        SetLocalIntranetSites                  = 'All' #All, Forest, Domain, None

        #Azure
        MinimumAzureModuleVersion              = '4.0.0'
        DefaultAzureRoleSize                   = 'D'

        #Exchange
        ExchangeUcmaDownloadLink               = 'http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe'
        Exchange2013DownloadLink               = 'https://download.microsoft.com/download/D/E/1/DE1C3D22-28A6-4A30-9811-0A0539385E51/Exchange2013-x64-cu17.exe'
        #Exchange2016DownloadLink = 'https://download.microsoft.com/download/3/9/B/39B8DDA8-509C-4B9E-BCE9-4CD8CDC9A7DA/Exchange2016-x64.exe' the Exchange CUs are ISOs again

        #Office
        OfficeDeploymentTool                   = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_7614-3602.exe'

        #SysInternals
        SysInternalsUrl                        = 'https://technet.microsoft.com/en-us/sysinternals/bb842062'
        SysInternalsDownloadUrl                = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'

        #.net Framework
        dotnet452DownloadLink                  = 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
        dotnet46DownloadLink                   = 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe'
        dotnet462DownloadLink                  = 'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe'

        #SQL Server 2016 Management Studio
        Sql2016ManagementStudio                = 'https://go.microsoft.com/fwlink/?LinkID=840946'
        Sql2017ManagementStudio                = 'https://go.microsoft.com/fwlink/?linkid=858904'

        # Notification settings - see AutomatedLabNotifications module manifest for provider settings
        NotificationProviders                  = @(
            'Toast'
        )

        #SQL Server sample database contents
        SQLServer2008                          = 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063'
        SQLServer2008R2                        = 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063'
        SQLServer2012                          = 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak'
        SQLServer2014                          = 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2014.bak'
        SQLServer2016                          = 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'
        SQLServer2017                          = 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'

        #Access Database Engine
        AccessDatabaseEngine2016x86            = 'https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/AccessDatabaseEngine.exe'

        #TFS Build Agent
        BuildAgentUri                          = 'http://go.microsoft.com/fwlink/?LinkID=829054'


        # OpenSSH
        OpenSshUri                             = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.6.0.0p1-Beta/OpenSSH-Win64.zip'
    }
}