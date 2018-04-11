@{
    RootModule             = 'AutomatedLabDefinition.psm1'
    
    ModuleVersion          = '4.5.7.0'
    
    GUID                   = 'e85df8ec-4ce6-4ecc-9720-1d08e14f27ad'
    
    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
    
    CompanyName            = 'AutomatedLab Team'
    
    Copyright              = '2018'
    
    Description            = 'The module creates the lab and machine definition for the AutomatedLab module saved in XML'
    
    PowerShellVersion      = '4.0'
    
    DotNetFrameworkVersion = '4.0'

    ModuleList             = @('AutomatedLabDefinition')
    
    NestedModules          = @('AutomatedLabDefinitionNetwork.psm1', 'AutomatedLabDefinitionAzureServices.psm1')
    
    FileList               = @('AutomatedLabDefinition.psm1', 'AutomatedLabDefinition.init.ps1', 'AutomatedLabDefinitionNetwork.psm1', 'AutomatedLabDefinitionAzureServices.psm1')
    
    RequiredModules        = @(
        'AutomatedLabUnattended'
        'PSLog'
    )

    CmdletsToExport        = @()

    FunctionsToExport      = @(
        'Add-LabAzureWebAppDefinition'
        'Add-LabAzureAppServicePlanDefinition'
        'Add-LabDiskDefinition'
        'Add-LabDomainDefinition'
        'Add-LabIsoImageDefinition'
        'Add-LabMachineDefinition'
        'Add-LabVirtualNetworkDefinition'
        'Export-LabDefinition'
		'Get-LabAzureWebAppDefinition'
        'Get-LabAzureAppServicePlanDefinition'
        'Get-DiskSpeed'
        'Get-LabAvailableAddresseSpace'
        'Get-LabDefinition'
        'Get-LabDomainDefinition'
        'Get-LabIsoImageDefinition'
        'Get-LabMachineDefinition'
        'Get-LabMachineRoleDefinition'
        'Get-LabPostInstallationActivity'
        'Get-LabVirtualNetwork'
        'Get-LabVirtualNetworkDefinition'
        'Get-LabVolumesOnPhysicalDisks'
        'New-LabDefinition'
        'New-LabNetworkAdapterDefinition'
        'Remove-LabDomainDefinition'
        'Remove-LabIsoImageDefinition'
        'Remove-LabMachineDefinition'
        'Remove-LabVirtualNetworkDefinition'
        'Repair-LabDuplicateIpAddresses'
        'Set-LabDefinition'
        'Set-LabLocalVirtualMachineDiskAuto'
        'Test-LabDefinition'
    )

    PrivateData = @{
        LabFileName = 'Lab.xml'
        MachineFileName = 'Machines.xml'
        DiskFileName = 'Disks.xml'
        
        MemoryWeight_RootDC = 1
        MemoryWeight_FirstChildDC = 1
        MemoryWeight_DC = 1
        MemoryWeight_WebServer = 2
        MemoryWeight_FileServer = 2
        MemoryWeight_SQLServer2012 = 4
        MemoryWeight_SQLServer2014 = 4
        MemoryWeight_ExchangeServer = 4
        MemoryWeight_CARoot = 1
        MemoryWeight_CASubordinate = 1
        MemoryWeight_ConfigManager = 3
        MemoryWeight_Orchestrator = 2
        MemoryWeight_OpsMgr = 3
        MemoryWeight_DevTools = 2

        DefaultAddressSpace = '192.168.10.0/24'

        ValidationSettings = @{

            ValidRoleProperties = @{
                ADFS = 'DisplayName', 'ServiceName', 'ServicePassword'

                CaRoot = 'CACommonName', 'CAType', 'KeyLength', 'CryptoProviderName', 'HashAlgorithmName', 'DatabaseDirectory', 'LogDirectory', 'ValidityPeriod', 'ValidityPeriodUnits', 'CertsValidityPeriod', 'CertsValidityPeriodUnits', 'CRLPeriod', 'CRLPeriodUnits', 'CRLOverlapPeriod', 'CRLOverlapUnits', 'CRLDeltaPeriod', 'CRLDeltaPeriodUnits', 'UseLDAPAIA', 'UseHTTPAIA', 'AIAHTTPURL01', 'AIAHTTPURL02', 'AIAHTTPURL01UploadLocation', 'AIAHTTPURL02UploadLocation', 'UseLDAPCRL', 'UseHTTPCRL', 'CDPHTTPURL01', 'CDPHTTPURL02', 'CDPHTTPURL01UploadLocation', 'CDPHTTPURL02UploadLocation', 'InstallWebEnrollment', 'InstallWebRole', 'CPSURL', 'CPSText', 'InstallOCSP', 'OCSPHTTPURL01', 'OCSPHTTPURL02', 'DoNotLoadDefaultTemplates'
                CaSubordinate = 'ParentCA', 'ParentCALogicalName', 'CACommonName', 'CAType', 'KeyLength', 'CryptoProviderName', 'HashAlgorithmName', 'DatabaseDirectory', 'LogDirectory', 'ValidityPeriod', 'ValidityPeriodUnits', 'CertsValidityPeriod', 'CertsValidityPeriodUnits', 'CRLPeriod', 'CRLPeriodUnits', 'CRLOverlapPeriod', 'CRLOverlapUnits', 'CRLDeltaPeriod', 'CRLDeltaPeriodUnits', 'UseLDAPAIA', 'UseHTTPAIA', 'AIAHTTPURL01', 'AIAHTTPURL02', 'AIAHTTPURL01UploadLocation', 'AIAHTTPURL02UploadLocation', 'UseLDAPCRL', 'UseHTTPCRL', 'CDPHTTPURL01', 'CDPHTTPURL02', 'CDPHTTPURL01UploadLocation', 'CDPHTTPURL02UploadLocation', 'InstallWebEnrollment', 'InstallWebRole', 'CPSURL', 'CPSText', 'InstallOCSP', 'OCSPHTTPURL01', 'OCSPHTTPURL02', 'DoNotLoadDefaultTemplates'

                RootDC = 'DomainFunctionalLevel', 'ForestFunctionalLevel', 'SiteName', 'SiteSubnet', 'NetBiosDomainName'
                FirstChildDC = 'ParentDomain', 'NewDomain', 'DomainFunctionalLevel', 'SiteName', 'SiteSubnet', 'NetBIOSDomainName'
                DC = 'IsReadOnly', 'SiteName', 'SiteSubnet'

                Office2016 = 'SharedComputerLicensing'

                Orchestrator2012 = 'DatabaseServer', 'DatabaseName', 'ServiceAccount', 'ServiceAccountPassword'

                DSCPullServer = 'DoNotPushLocalModules', 'DatabaseEngine'
            }

            MandatoryRoleProperties = @{
                ADFSProxy = @('AdfsFullName', 'AdfsDomainName')
            }

        }
    }
}
