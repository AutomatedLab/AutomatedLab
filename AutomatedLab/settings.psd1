@{
    Settings = @{
        "SubscribedProviders"                  = @(
            "Toast"
        )
        "NotificationProviders"                = @(
            @{
                "Ifttt" = @{
                    "Key"       = "Your IFTTT key here"
                    "EventName" = "The name of your IFTTT event"
                }
            }
            @{
                "Mail" = @{
                    "Port"       = 25
                    "SmtpServer" = "Your SMTP server here"
                    "To"         = @(
                        "Your recipient array here"
                    )
                    "From"       = "Your sender here"
                    "Priority"   = "Normal"
                    "CC"         = @(
                        "Your CC array here"
                    )
                }
            }
            @{
                "Toast" = @{
                    "Image" = "https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/master/Assets/Automated-Lab_icon512.png"
                }
            }
            @{
                "Voice" = @{
                    "Culture" = "en-us"
                    "Age"     = "Senior"
                    "Gender"  = "female"
                }
            }
        )
        "Logging"                              = @{
            "TruncateLength" = 50
            "TruncateTypes"  = @(
                "System.Management.Automation.ScriptBlock"
            )
            "DefaultFolder"  = $null
            "DefaultName"    = "PSLog"
            "Level"          = "All"
            "Silent"         = $false
            "AutoStart"      = $true
        }
        "MachineFileName"                      = "Machines.xml"
        "DiskFileName"                         = "Disks.xml"
        "LabFileName"                          = "Lab.xml"        
        DefaultAddressSpace                    = '192.168.10.0/24'
        "ValidationSettings"                   = @{
            "ValidRoleProperties"     = @{
                "Orchestrator2012" = @(
                    "DatabaseServer"
                    "DatabaseName"
                    "ServiceAccount"
                    "ServiceAccountPassword"
                )
                "DC"               = @(
                    "IsReadOnly"
                    "SiteName"
                    "SiteSubnet"
                )
                "CaSubordinate"    = @(
                    "ParentCA"
                    "ParentCALogicalName"
                    "CACommonName"
                    "CAType"
                    "KeyLength"
                    "CryptoProviderName"
                    "HashAlgorithmName"
                    "DatabaseDirectory"
                    "LogDirectory"
                    "ValidityPeriod"
                    "ValidityPeriodUnits"
                    "CertsValidityPeriod"
                    "CertsValidityPeriodUnits"
                    "CRLPeriod"
                    "CRLPeriodUnits"
                    "CRLOverlapPeriod"
                    "CRLOverlapUnits"
                    "CRLDeltaPeriod"
                    "CRLDeltaPeriodUnits"
                    "UseLDAPAIA"
                    "UseHTTPAIA"
                    "AIAHTTPURL01"
                    "AIAHTTPURL02"
                    "AIAHTTPURL01UploadLocation"
                    "AIAHTTPURL02UploadLocation"
                    "UseLDAPCRL"
                    "UseHTTPCRL"
                    "CDPHTTPURL01"
                    "CDPHTTPURL02"
                    "CDPHTTPURL01UploadLocation"
                    "CDPHTTPURL02UploadLocation"
                    "InstallWebEnrollment"
                    "InstallWebRole"
                    "CPSURL"
                    "CPSText"
                    "InstallOCSP"
                    "OCSPHTTPURL01"
                    "OCSPHTTPURL02"
                    "DoNotLoadDefaultTemplates"
                )
                "Office2016"       = "SharedComputerLicensing"
                "DSCPullServer"    = @(
                    "DoNotPushLocalModules"
                    "DatabaseEngine"
                    "SqlServer"
                    "DatabaseName"
                )
                "FirstChildDC"     = @(
                    "ParentDomain"
                    "NewDomain"
                    "DomainFunctionalLevel"
                    "SiteName"
                    "SiteSubnet"
                    "NetBIOSDomainName"
                )
                "ADFS"             = @(
                    "DisplayName"
                    "ServiceName"
                    "ServicePassword"
                )
                "RootDC"           = @(
                    "DomainFunctionalLevel"
                    "ForestFunctionalLevel"
                    "SiteName"
                    "SiteSubnet"
                    "NetBiosDomainName"
                )
                "CaRoot"           = @(
                    "CACommonName"
                    "CAType"
                    "KeyLength"
                    "CryptoProviderName"
                    "HashAlgorithmName"
                    "DatabaseDirectory"
                    "LogDirectory"
                    "ValidityPeriod"
                    "ValidityPeriodUnits"
                    "CertsValidityPeriod"
                    "CertsValidityPeriodUnits"
                    "CRLPeriod"
                    "CRLPeriodUnits"
                    "CRLOverlapPeriod"
                    "CRLOverlapUnits"
                    "CRLDeltaPeriod"
                    "CRLDeltaPeriodUnits"
                    "UseLDAPAIA"
                    "UseHTTPAIA"
                    "AIAHTTPURL01"
                    "AIAHTTPURL02"
                    "AIAHTTPURL01UploadLocation"
                    "AIAHTTPURL02UploadLocation"
                    "UseLDAPCRL"
                    "UseHTTPCRL"
                    "CDPHTTPURL01"
                    "CDPHTTPURL02"
                    "CDPHTTPURL01UploadLocation"
                    "CDPHTTPURL02UploadLocation"
                    "InstallWebEnrollment"
                    "InstallWebRole"
                    "CPSURL"
                    "CPSText"
                    "InstallOCSP"
                    "OCSPHTTPURL01"
                    "OCSPHTTPURL02"
                    "DoNotLoadDefaultTemplates"
                )
            }
            "MandatoryRoleProperties" = @{
                "ADFSProxy" = @(
                    "AdfsFullName"
                    "AdfsDomainName"
                )
            }
        }
        #Timeouts
        Timeout_WaitLabMachine_Online          = 60
        Timeout_StartLabMachine_Online         = 60
        Timeout_RestartLabMachine_Shutdown     = 30
        Timeout_StopLabMachine_Shutdown        = 30
        Timeout_TestPortInSeconds              = 2
        
        Timeout_InstallLabCAInstallation       = 40
        
        Timeout_DcPromotionRestartAfterDcpromo = 60
        Timeout_DcPromotionAdwsReady           = 20
        
        Timeout_Sql2008Installation            = 90
        Timeout_Sql2012Installation            = 90
        Timeout_Sql2014Installation            = 90

        Timeout_VisualStudio2013Installation   = 90
        Timeout_VisualStudio2015Installation   = 90

        DefaultProgressIndicator               = 10

        #PSSession settings
        InvokeLabCommandRetries                = 3
        InvokeLabCommandRetryIntervalInSeconds = 10
        MaxPSSessionsPerVM                     = 5
        DoNotUseGetHostEntryInNewLabPSSession  = $true

        #DSC
        DscMofPath                             = '"$(Get-LabSourcesLocationInternal -Local)\DscConfigurations"'
        DscPullServerRegistrationKey           = 'ec717ee9-b343-49ee-98a2-26e53939eecf' #used on all Dsc Pull servers and clients

        #General VM settings
        DisableWindowsDefender                 = $true
        DoNotSkipNonNonEnglishIso              = $false #even if AL detects non en-us images, these are not supported and may not work

        #Hyper-V VM Settings
        SetLocalIntranetSites                  = 'All' #All, Forest, Domain, None

        #Hyper-V Network settings
        MacAddressPrefix                       = '0017FB'

        #Host Settings
        DiskDeploymentInProgressPath           = "C:\ProgramData\AutomatedLab\LabDiskDeploymentInProgress.txt"

        #Azure
        MinimumAzureModuleVersion              = '1.0'
        DefaultAzureRoleSize                   = 'D'

        #Office
        OfficeDeploymentTool                   = 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_7614-3602.exe'

        #SysInternals
        SysInternalsUrl                        = 'https://technet.microsoft.com/en-us/sysinternals/bb842062'
        SysInternalsDownloadUrl                = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'

        #.net Framework
        dotnet452DownloadLink                  = 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
        dotnet46DownloadLink                   = 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe'
        dotnet462DownloadLink                  = 'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe'
        dotnet471DownloadLink                  = 'https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033342-x86-x64-AllOS-ENU.exe'
        dotnet472DownloadLink                  = 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'

        # C++ redist
        cppredist64                            = 'https://aka.ms/vs/15/release/vc_redist.x64.exe'
        cppredist32                            = 'https://aka.ms/vs/15/release/vc_redist.x86.exe'

        #SQL Server 2016 Management Studio
        Sql2016ManagementStudio                = 'https://go.microsoft.com/fwlink/?LinkID=840946'
        Sql2017ManagementStudio                = 'https://go.microsoft.com/fwlink/?linkid=858904'

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

        AzureLocationsUrls                     = @{
            "West Europe"         = "speedtestwe"
            "Southeast Asia"      = "speedtestsea" 
            "East Asia"           = "speedtestea"
            "North Central US"    = "speedtestnsus"
            "North Europe"        = "speedtestne"
            "South Central US"    = "speedtestscus"
            "West US"             = "speedtestwus"
            "East US"             = "speedtesteus"
            "Japan East"          = "speedtestjpe"
            "Japan West"          = "speedtestjpw"
            "Brazil South"        = "speedtestbs"
            "Central US"          = "speedtestcus"
            "East US 2"           = "speedtesteus2"
            "Australia Southeast" = "mickmel"
            "Australia East"      = "micksyd"
            "West UK"             = "speedtestukw"
            "South UK"            = "speedtestuks"
            "Canada Central"      = "speedtestcac"
            "Canada East"         = "speedtestcae"
            "West US 2"           = "speedtestwestus2"
            "West India"          = "speedtestwestindia"
            "East India"          = "speedtesteastindia"
            "Central India"       = "speedtestcentralindia"
            "Korea Central"       = "speedtestkoreacentral"
            "Korea South"         = "speedtestkoreasouth"
            "West Central US"     = "speedtestwestcentralus"
            "France Central"      = "speedtestfrc"
        }

        SupportGen2VMs                         = $true
        AzureRetryCount                        = 3
    }
}