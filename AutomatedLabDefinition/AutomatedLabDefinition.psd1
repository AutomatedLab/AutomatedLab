@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess = 'AutomatedLabDefinition.psm1'
	
    # Version number of this module.
    ModuleVersion = '3.9.0.5'
	
    # ID used to uniquely identify this module
    GUID = 'e85df8ec-4ce6-4ecc-9720-1d08e14f27ad'
	
    # Author of this module
    Author = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
	
    # Company or vendor of this module
    CompanyName = 'AutomatedLab Team'
	
    # Copyright statement for this module
    Copyright = '2016'
	
    # Description of the functionality provided by this module
    Description = 'The module creates the lab and machine definition for the AutomatedLab module saved in XML'
	
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'
	
    # Minimum version of the .NET Framework required by this module
    DotNetFrameworkVersion = '4.0'
	
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @('AutomatedLabDefinition.init.ps1')
	
    # Modules to import as nested modules of the module specified in ModuleToProcess
    NestedModules = @('AutomatedLabDefinitionNetwork.psm1')
	
    # List of all modules packaged with this module
    ModuleList = @('AutomatedLabDefinition.psm1', 'AutomatedLabDefinitionNetwork.psm1')
	
    # List of all files packaged with this module
    FileList = @('AutomatedLabDefinition.psm1', 'AutomatedLabDefinition.init.ps1', 'AutomatedLabDefinitionNetwork.psm1')
	
    # Private data to pass to the module specified in ModuleToProcess
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

                RootDC = 'DomainFunctionalLevel', 'ForestFunctionalLevel', 'SiteName', 'SiteSubnet'
                FirstChildDC = 'ParentDomain', 'NewDomain', 'DomainFunctionalLevel', 'SiteName', 'SiteSubnet'
				DC = 'IsReadOnly', 'SiteName', 'SiteSubnet'

				Exchange2013 = 'OrganizationName'
				Exchange2016 = 'OrganizationName'

				Orchestrator2012 = 'DatabaseServer', 'DatabaseName', 'ServiceAccount', 'ServiceAccountPassword'
            }

            MandatoryRoleProperties = @{
                ADFSProxy = @('AdfsFullName', 'AdfsDomainName')
            }

        }
    }
}