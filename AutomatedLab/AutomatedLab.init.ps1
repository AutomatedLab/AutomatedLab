if ($PSEdition -eq 'Core')
{
	Add-Type -Path $PSScriptRoot\lib\core\AutomatedLab.dll
}
else
{
	Add-Type -Path $PSScriptRoot\lib\full\AutomatedLab.dll
}

if ((Get-Module -ListAvailable Ships) -and (Get-Module -ListAvailable AutomatedLab.Ships))
{
    Import-Module Ships,AutomatedLab.Ships
    [void] (New-PSDrive -PSProvider SHiPS -Name Labs -Root "AutomatedLab.Ships#LabHost" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarning -Value true

Set-Alias -Name Write-Host -Value Write-PSFMessageProxy -Scope Script
Set-Alias -Name Write-Error -Value Write-PSFMessageProxy -Scope Script
Set-Alias -Name Write-Warning -Value Write-PSFMessageProxy -Scope Script
Set-Alias -Name Write-Debug -Value Write-PSFMessageProxy -Scope Script
Set-Alias -Name Write-Verbose -Value Write-PSFMessageProxy -Scope Script

#region Register default configuration if not present
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Ifttt.Key' -Value 'Your IFTTT key here' -Initialize -Validation string -Description "IFTTT Key Name"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Ifttt.EventName' -Value 'The name of your IFTTT event' -Initialize -Validation String -Description "IFTTT Event Name"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.Port' -Value 25 -Initialize -Validation integer -Description "Port of your SMTP Server"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.SmtpServer' -Value 'your SMTP server here' -Initialize -Validation string -Description "Adress of your SMTP server"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.To' -Value @('Recipients here') -Initialize -Validation stringarray -Description "A list of default recipients"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.From' -Value "$($env:USERNAME)@localhost" -Initialize -Validation string -Description "Your sender address"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.Priority' -Value 'Normal' -Initialize -Validation string -Description "Priority of your message"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Mail.CC' -Value @('Recipients here') -Initialize -Validation stringarray -Description "A list of default CC recipients"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Toast.Image' -Value 'https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/master/Assets/Automated-Lab_icon512.png' -Initialize -Validation string -Description "The image for your toast notification"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Voice.Culture' -Value 'en-us' -Initialize -Validation string -Description "Voice culture, needs to be available and defaults to en-us"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.NotificationProviders.Voice.Gender' -Value 'female' -Initialize -Validation string -Description "Gender of voice to use"
Set-PSFConfig -Module 'AutomatedLab' -Name 'Notifications.SubscribedProviders' -Value @('Toast') -Initialize -Validation stringarray -Description 'List of subscribed providers'
Set-PSFConfig -Module 'AutomatedLab' -Name 'MachineFileName' -Value 'Machines.xml' -Initialize -Validation string -Description 'The file name for the deserialized machines. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'DiskFileName' -Value 'Disks.xml' -Initialize -Validation string -Description 'The file name for the deserialized disks. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'LabFileName' -Value 'Lab.xml' -Initialize -Validation string -Description 'The file name for the deserialized labs. Do not change unless you know what you are doing.'
Set-PSFConfig -Module 'AutomatedLab' -Name 'DefaultAddressSpace' -Value '192.168.10.0/24' -Initialize -Validation string -Description 'Default address space if no address space is selected'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_WaitLabMachine_Online -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for Wait-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_StartLabMachine_Online -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for Start-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_RestartLabMachine_Shutdown -Value 30 -Initialize -Validation integer -Description 'Timeout in minutes for Restart-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_StopLabMachine_Shutdown -Value 30 -Initialize -Validation integer -Description 'Timeout in minutes for Stop-LabVm'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_TestPortInSeconds -Value 2 -Initialize -Validation integer -Description 'Timeout in seconds for Test-Port'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_InstallLabCAInstallation -Value 40 -Initialize -Validation integer -Description 'Timeout in minutes for CA setup'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_DcPromotionRestartAfterDcpromo -Value 60 -Initialize -Validation integer -Description 'Timeout in minutes for restart after DC Promo'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_DcPromotionAdwsReady -Value 20 -Initialize -Validation integer -Description 'Timeout in minutes for availability of ADWS after DC Promo'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2008Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2008'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2012Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2012'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_Sql2014Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for SQL 2014'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_VisualStudio2013Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for VS 2013'
Set-PSFConfig -Module 'AutomatedLab' -Name Timeout_VisualStudio2015Installation -Value 90 -Initialize -Validation integer -Description 'Timeout in minutes for VS 2015'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultProgressIndicator -Value 10 -Initialize -Validation integer -Description 'After how many minutes will a progress indicator be written'

#PSSession settings
Set-PSFConfig -Module 'AutomatedLab' -Name InvokeLabCommandRetries -Value 3 -Initialize -Validation integer -Description 'Number of retries for Invoke-LabCommand'
Set-PSFConfig -Module 'AutomatedLab' -Name InvokeLabCommandRetryIntervalInSeconds -Value 10 -Initialize -Validation integer -Description 'Retry interval for Invoke-LabCommand'
Set-PSFConfig -Module 'AutomatedLab' -Name MaxPSSessionsPerVM -Value 5 -Initialize -Validation integer -Description 'Maximum number of sessions per VM'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotUseGetHostEntryInNewLabPSSession -Value $true -Initialize -Validation bool -Description 'Do not use hosts file for session creation'

#DSC
Set-PSFConfig -Module 'AutomatedLab' -Name DscMofPath -Value 'DscConfigurations' -Initialize -Validation string -Description 'Default path for MOF files on Pull server'
Set-PSFConfig -Module 'AutomatedLab' -Name DscPullServerRegistrationKey -Value 'ec717ee9-b343-49ee-98a2-26e53939eecf'  -Initialize -Validation string  -Description 'DSC registration key used on all Dsc Pull servers and clients'

#General VM settings
Set-PSFConfig -Module 'AutomatedLab' -Name DisableWindowsDefender -Value $true -Initialize -Validation bool -Description 'Indicates that Windows Defender should be disabled on the lab VMs'
Set-PSFConfig -Module 'AutomatedLab' -Name DoNotSkipNonNonEnglishIso -Value $false -Initialize -Validation bool  -Description 'Indicates that non English ISO files will not be skipped'

#Hyper-V VM Settings
Set-PSFConfig -Module 'AutomatedLab' -Name SetLocalIntranetSites -Value 'All'  -Initialize -Validation string  -Description 'All, Forest, Domain, None'

#Hyper-V Network settings
Set-PSFConfig -Module 'AutomatedLab' -Name MacAddressPrefix -Value '0017FB' -Initialize -Validation string -Description 'The MAC address prefix for Hyper-V labs'

#Host Settings
Set-PSFConfig -Module 'AutomatedLab' -Name DiskDeploymentInProgressPath -Value 'C:\ProgramData\AutomatedLab\LabDiskDeploymentInProgress.txt' -Initialize -Validation string -Description 'The file indicating that Hyper-V disks are being configured to reduce disk congestion'

#Azure
Set-PSFConfig -Module 'AutomatedLab' -Name MinimumAzureModuleVersion -Value '2.0.0' -Initialize -Validation string -Description 'The minimum expected Azure module version'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultAzureRoleSize -Value 'D' -Initialize -Validation string -Description 'The default Azure role size, e.g. from Get-LabAzureAvailableRoleSize'
Set-PSFConfig -Module 'AutomatedLab' -Name LabSourcesMaxFileSizeMb -Value 50 -Initialize -Validation integer -Description 'The default file size for Sync-LabAzureLabSources'

#Office
Set-PSFConfig -Module 'AutomatedLab' -Name OfficeDeploymentTool -Value 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11107-33602.exe' -Initialize -Validation string -Description 'Link to Microsoft Office deployment tool'

#SysInternals
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsUrl -Value 'https://technet.microsoft.com/en-us/sysinternals/bb842062' -Initialize -Validation string -Description 'Link to SysInternals to check for newer versions'
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsDownloadUrl -Value 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -Initialize -Validation string -Description 'Link to download of SysInternals'

#.net Framework
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet452DownloadLink -Value 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.5.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet46DownloadLink -Value 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet462DownloadLink -Value 'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet471DownloadLink -Value 'https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033342-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.1'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet472DownloadLink -Value 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.2'

# C++ redist
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x86)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2013 -Value 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2013 -Value 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x86)'

#SQL Server 2016 Management Studio
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2016ManagementStudio -Value 'https://go.microsoft.com/fwlink/?LinkID=840946' -Initialize -Validation string -Description 'Link to SSMS 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2017ManagementStudio -Value 'https://go.microsoft.com/fwlink/?linkid=858904' -Initialize -Validation string -Description 'Link to SSMS 2017'

#SQL Server sample database contents
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008R2 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008 R2'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2012 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2012'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2014 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2014.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2014'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2016 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2017 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2017'

#Access Database Engine
Set-PSFConfig -Module 'AutomatedLab' -Name AccessDatabaseEngine2016x86 -Value 'https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/AccessDatabaseEngine.exe' -Initialize -Validation string -Description 'Link to Access Database Engine (required for DSC Pull)'
#TFS Build Agent
Set-PSFConfig -Module 'AutomatedLab' -Name BuildAgentUri -Value 'https://vstsagentpackage.azureedge.net/agent/2.136.1/vsts-agent-win-x64-2.136.1.zip' -Initialize -Validation string -Description 'Link to Azure DevOps/VSTS Build Agent'

# OpenSSH
Set-PSFConfig -Module 'AutomatedLab' -Name OpenSshUri -Value 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.6.0.0p1-Beta/OpenSSH-Win64.zip' -Initialize -Validation string -Description 'Link to OpenSSH binaries'

Set-PSFConfig -Module 'AutomatedLab' -Name 'AzureLocationsUrls' -Value @{
    'West Europe'         = 'speedtestwe'
    'Southeast Asia'      = 'speedtestsea'
    'East Asia'           = 'speedtestea'
    'North Central US'    = 'speedtestnsus'
    'North Europe'        = 'speedtestne'
    'South Central US'    = 'speedtestscus'
    'West US'             = 'speedtestwus'
    'East US'             = 'speedtesteus'
    'Japan East'          = 'speedtestjpe'
    'Japan West'          = 'speedtestjpw'
    'Brazil South'        = 'speedtestbs'
    'Central US'          = 'speedtestcus'
    'East US 2'           = 'speedtesteus2'
    'Australia Southeast' = 'mickmel'
    'Australia East'      = 'micksyd'
    'West UK'             = 'speedtestukw'
    'South UK'            = 'speedtestuks'
    'Canada Central'      = 'speedtestcac'
    'Canada East'         = 'speedtestcae'
    'West US 2'           = 'speedtestwestus2'
    'West India'          = 'speedtestwestindia'
    'East India'          = 'speedtesteastindia'
    'Central India'       = 'speedtestcentralindia'
    'Korea Central'       = 'speedtestkoreacentral'
    'Korea South'         = 'speedtestkoreasouth'
    'West Central US'     = 'speedtestwestcentralus'
    'France Central'      = 'speedtestfrc'
} -Initialize -Description 'Hashtable containing all Azure Speed Test URLs for automatic region placement'

Set-PSFConfig -Module 'AutomatedLab' -Name SupportGen2VMs -Value $true -Initialize -Validation bool -Description 'Indicates that Gen2 VMs are supported'
Set-PSFConfig -Module 'AutomatedLab' -Name AzureRetryCount -Value 3 -Initialize -Validation integer -Description 'The number of retries for Azure actions like creating a virtual network'

# Validation
Set-PSFConfig -Module AutomatedLab -Name ValidationSettings -Value @{
    ValidRoleProperties     = @{
        Orchestrator2012 = @(
            'DatabaseServer'
            'DatabaseName'
            'ServiceAccount'
            'ServiceAccountPassword'
        )
        DC               = @(
            'IsReadOnly'
            'SiteName'
            'SiteSubnet'
            'DatabasePath'
            'LogPath'
            'SysvolPath'
            'DsrmPassword'
        )
        CaSubordinate    = @(
            'ParentCA'
            'ParentCALogicalName'
            'CACommonName'
            'CAType'
            'KeyLength'
            'CryptoProviderName'
            'HashAlgorithmName'
            'DatabaseDirectory'
            'LogDirectory'
            'ValidityPeriod'
            'ValidityPeriodUnits'
            'CertsValidityPeriod'
            'CertsValidityPeriodUnits'
            'CRLPeriod'
            'CRLPeriodUnits'
            'CRLOverlapPeriod'
            'CRLOverlapUnits'
            'CRLDeltaPeriod'
            'CRLDeltaPeriodUnits'
            'UseLDAPAIA'
            'UseHTTPAIA'
            'AIAHTTPURL01'
            'AIAHTTPURL02'
            'AIAHTTPURL01UploadLocation'
            'AIAHTTPURL02UploadLocation'
            'UseLDAPCRL'
            'UseHTTPCRL'
            'CDPHTTPURL01'
            'CDPHTTPURL02'
            'CDPHTTPURL01UploadLocation'
            'CDPHTTPURL02UploadLocation'
            'InstallWebEnrollment'
            'InstallWebRole'
            'CPSURL'
            'CPSText'
            'InstallOCSP'
            'OCSPHTTPURL01'
            'OCSPHTTPURL02'
            'DoNotLoadDefaultTemplates'
        )
        Office2016       = 'SharedComputerLicensing'
        DSCPullServer    = @(
            'DoNotPushLocalModules'
            'DatabaseEngine'
            'SqlServer'
            'DatabaseName'
        )
        FirstChildDC     = @(
            'ParentDomain'
            'NewDomain'
            'DomainFunctionalLevel'
            'SiteName'
            'SiteSubnet'
            'NetBIOSDomainName'
            'DatabasePath'
            'LogPath'
            'SysvolPath'
            'DsrmPassword'
        )
        ADFS             = @(
            'DisplayName'
            'ServiceName'
            'ServicePassword'
        )
        RootDC           = @(
            'DomainFunctionalLevel'
            'ForestFunctionalLevel'
            'SiteName'
            'SiteSubnet'
            'NetBiosDomainName'
            'DatabasePath'
            'LogPath'
            'SysvolPath'
            'DsrmPassword'
        )
        CaRoot           = @(
            'CACommonName'
            'CAType'
            'KeyLength'
            'CryptoProviderName'
            'HashAlgorithmName'
            'DatabaseDirectory'
            'LogDirectory'
            'ValidityPeriod'
            'ValidityPeriodUnits'
            'CertsValidityPeriod'
            'CertsValidityPeriodUnits'
            'CRLPeriod'
            'CRLPeriodUnits'
            'CRLOverlapPeriod'
            'CRLOverlapUnits'
            'CRLDeltaPeriod'
            'CRLDeltaPeriodUnits'
            'UseLDAPAIA'
            'UseHTTPAIA'
            'AIAHTTPURL01'
            'AIAHTTPURL02'
            'AIAHTTPURL01UploadLocation'
            'AIAHTTPURL02UploadLocation'
            'UseLDAPCRL'
            'UseHTTPCRL'
            'CDPHTTPURL01'
            'CDPHTTPURL02'
            'CDPHTTPURL01UploadLocation'
            'CDPHTTPURL02UploadLocation'
            'InstallWebEnrollment'
            'InstallWebRole'
            'CPSURL'
            'CPSText'
            'InstallOCSP'
            'OCSPHTTPURL01'
            'OCSPHTTPURL02'
            'DoNotLoadDefaultTemplates'
        )
    }
    MandatoryRoleProperties = @{
        ADFSProxy = @(
            'AdfsFullName'
            'AdfsDomainName'
        )
    }
} -Initialize -Description 'Validation settings for lab validation. Please do not modify unless you know what you are doing.'

#endregion

#region ArgumentCompleter
Register-PSFTeppScriptblock -Name 'AutomatedLab-NotificationProviders' -ScriptBlock {
	(Get-PSFConfig -Module AutomatedLab -Name Notifications.NotificationProviders*).FullName | Foreach-Object {($_ -split '\.')[3]} | Select -Unique
}

Register-PSFTeppScriptblock -Name 'AutomatedLab-OperatingSystem' -ScriptBlock {
    if (-not $global:AL_OperatingSystems)
    {
        $global:AL_OperatingSystems = Get-LabAvailableOperatingSystem -Path $labSources\ISOs -UseOnlyCache -NoDisplay
    }

    $global:AL_OperatingSystems.OperatingSystemName
}

Register-PSFTeppscriptblock -Name 'AutomatedLab-Labs' -ScriptBlock {
    $path = "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData))\AutomatedLab\Labs"
    (Get-ChildItem -Path $path -Directory).Name
}

Register-PSFTeppScriptblock -Name 'AutomatedLab-Roles' -ScriptBlock {
    [System.Enum]::GetNames([AutomatedLab.Roles])
}

Register-PSFTeppScriptblock -Name 'AutomatedLab-Domains' -ScriptBlock {
    (Get-LabDefinition -ErrorAction SilentlyContinue).Domains.Name
}

Register-PSFTeppScriptblock -Name 'AutomatedLab-ComputerName' -ScriptBlock {
    (Get-LabVM -All -IncludeLinux -SkipConnectionInfo).Name
}

Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter Roles -Name 'AutomatedLab-Roles'
Register-PSFTeppArgumentCompleter -Command Get-Lab, Remove-Lab, Import-Lab -Parameter Name -Name 'AutomatedLab-Labs'
Register-PSFTeppArgumentCompleter -Command Connect-Lab -Parameter SourceLab, DestinationLab -Name 'AutomatedLab-Labs'
Register-PSFTeppArgumentCompleter -Command Send-ALNotification -Parameter Provider -Name "AutomatedLab-NotificationProviders"
#endregion
