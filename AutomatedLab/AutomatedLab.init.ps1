if ($PSEdition -eq 'Core')
{
    Add-Type -Path $PSScriptRoot/lib/core/AutomatedLab.dll

    # These modules SHOULD be marked as Core compatible, as tested with Windows 10.0.18362.113
    # However, if they are not, they need to be imported.
    $requiredModules = @('Dism', 'International')

    $ipmoErr = $null # Initialize, otherwise Import-MOdule -Force will extend this variable indefinitely
    foreach ($module in $requiredModules)
    {
        Import-Module -SkipEditionCheck -Name $module -ErrorAction SilentlyContinue -ErrorVariable +ipmoErr
    }

    if ($ipmoErr)
    {
        Write-PSFMessage -Level Warning -Message "Could not import modules: $($ipmoErr.TargetObject -join ',') - your experience might be impacted."
    }
}
else
{
    Add-Type -Path $PSScriptRoot/lib/full/AutomatedLab.dll
}

$usedRelease = (Split-Path -Leaf -Path $PSScriptRoot) -as [version]
$currentRelease = try {((Invoke-RestMethod -Method Get -Uri https://api.github.com/repos/AutomatedLab/AutomatedLab/releases/latest -ErrorAction Stop).tag_Name -replace 'v') -as [Version] } catch {}

if ($null -ne $currentRelease -and $usedRelease -lt $currentRelease)
{
    Write-PSFMessage -Level Host -Message "Your version of AutomatedLab is outdated. Consider updating to the recent version, $currentRelease"
}

if ((Get-Module -ListAvailable Ships) -and (Get-Module -ListAvailable AutomatedLab.Ships))
{
    Import-Module Ships, AutomatedLab.Ships
    [void] (New-PSDrive -PSProvider SHiPS -Name Labs -Root "AutomatedLab.Ships#LabHost" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarnings -Value true

#region Register default configuration if not present
Set-PSFConfig -Module 'AutomatedLab' -Name LabAppDataRoot -Value (Join-Path ([System.Environment]::GetFolderPath('CommonApplicationData')) -ChildPath "AutomatedLab") -Initialize -Validation string -Description "Root folder to Labs, Assets and Stores"

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
Set-PSFConfig -Module 'AutomatedLab' -Name DisableConnectivityCheck -Value $false -Initialize -Validation bool -Description 'Indicates whether connectivity checks should be skipped. Certain systems like Azure DevOps build workers do not send ICMP packges and the method might always fail'

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
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultDnsForwarder1 -Value 1.1.1.1 -Initialize -Description 'If routing is installed on a Root DC, this forwarder is used'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultDnsForwarder2 -Value 8.8.8.8 -Initialize -Description 'If routing is installed on a Root DC, this forwarder is used'

#Hyper-V VM Settings
Set-PSFConfig -Module 'AutomatedLab' -Name SetLocalIntranetSites -Value 'All'  -Initialize -Validation string  -Description 'All, Forest, Domain, None'

#Hyper-V Network settings
Set-PSFConfig -Module 'AutomatedLab' -Name MacAddressPrefix -Value '0017FB' -Initialize -Validation string -Description 'The MAC address prefix for Hyper-V labs'

#Admin Center
Set-PSFConfig -Module 'AutomatedLab' -Name WacDownloadUrl -Value 'http://aka.ms/WACDownload' -Validation string -Initialize -Description 'Windows Admin Center Download URL'

#Host Settings
Set-PSFConfig -Module 'AutomatedLab' -Name DiskDeploymentInProgressPath -Value (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath "LabDiskDeploymentInProgress.txt") -Initialize -Validation string -Description 'The file indicating that Hyper-V disks are being configured to reduce disk congestion'
Set-PSFConfig -Module 'AutomatedLab' -Name SkipHostFileModification -Value $false -Initialize -Validation bool -Description 'Indicates that the hosts file should not be modified when deploying a new lab.'

#Azure
Set-PSFConfig -Module 'AutomatedLab' -Name MinimumAzureModuleVersion -Value '4.1.0' -Initialize -Validation string -Description 'The minimum expected Azure module version'
Set-PSFConfig -Module 'AutomatedLab' -Name DefaultAzureRoleSize -Value 'D' -Initialize -Validation string -Description 'The default Azure role size, e.g. from Get-LabAzureAvailableRoleSize'
Set-PSFConfig -Module 'AutomatedLab' -Name LabSourcesMaxFileSizeMb -Value 50 -Initialize -Validation integer -Description 'The default file size for Sync-LabAzureLabSources'
Set-PSFConfig -Module 'AutomatedLab' -Name AzureDiskSkus -Value @('Standard_LRS', 'Premium_LRS', 'StandardSSD_LRS') # 'UltraSSD_LRS' is not allowed!

#Office
Set-PSFConfig -Module 'AutomatedLab' -Name OfficeDeploymentTool -Value 'https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_12827-20268.exe' -Initialize -Validation string -Description 'Link to Microsoft Office deployment tool'

#SysInternals
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsUrl -Value 'https://technet.microsoft.com/en-us/sysinternals/bb842062' -Initialize -Validation string -Description 'Link to SysInternals to check for newer versions'
Set-PSFConfig -Module 'AutomatedLab' -Name SysInternalsDownloadUrl -Value 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -Initialize -Validation string -Description 'Link to download of SysInternals'

#.net Framework
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet452DownloadLink -Value 'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.5.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet46DownloadLink -Value 'http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet462DownloadLink -Value 'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.6.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet471DownloadLink -Value 'https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033342-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.1'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet472DownloadLink -Value 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe' -Initialize -Validation string -Description 'Link to .NET 4.7.2'
Set-PSFConfig -Module 'AutomatedLab' -Name dotnet48DownloadLink -Value 'https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe' -Initialize -Validation string -Description 'Link to .NET 4.8'

# C++ redist
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2017 -Value 'https://aka.ms/vs/15/release/vc_redist.x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2017 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2015 -Value 'https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2015 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2015 -Value 'https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2015 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2013 -Value 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2013 -Value 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2013 (x86)'

Set-PSFConfig -Module 'AutomatedLab' -Name cppredist64_2012 -Value 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2012 (x64)'
Set-PSFConfig -Module 'AutomatedLab' -Name cppredist32_2012 -Value 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe' -Initialize -Validation string -Description 'Link to VC++ redist 2012 (x86)'

#SQL Server 2016 Management Studio
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2016ManagementStudio -Value 'https://go.microsoft.com/fwlink/?LinkID=840946' -Initialize -Validation string -Description 'Link to SSMS 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2017ManagementStudio -Value 'https://go.microsoft.com/fwlink/?linkid=2099720' -Initialize -Validation string -Description 'Link to SSMS 2017 18.2'
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2019ManagementStudio -Value 'https://aka.ms/ssmsfullsetup' -Initialize -Validation string -Description 'Link to SSMS latest'

# SSRS
Set-PSFConfig -Module 'AutomatedLab' -Name SqlServerReportBuilder -Value https://download.microsoft.com/download/5/E/B/5EB40744-DC0A-47C0-8B0A-1830E74D3C23/ReportBuilder.msi
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2017SSRS -Value https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe
Set-PSFConfig -Module 'AutomatedLab' -Name Sql2019SSRS -Value https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe

#SQL Server sample database contents
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2008R2 -Value 'http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=478218&FileTime=129906742909030000&Build=21063' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2008 R2'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2012 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2012'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2014 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2014.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2014'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2016 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2016'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2017 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2017'
Set-PSFConfig -Module 'AutomatedLab' -Name SQLServer2019 -Value 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak' -Initialize -Validation string -Description 'Link to SQL sample DB for SQL 2019'

#Access Database Engine
Set-PSFConfig -Module 'AutomatedLab' -Name AccessDatabaseEngine2016x86 -Value 'https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/AccessDatabaseEngine.exe' -Initialize -Validation string -Description 'Link to Access Database Engine (required for DSC Pull)'
#TFS Build Agent
Set-PSFConfig -Module 'AutomatedLab' -Name BuildAgentUri -Value 'https://vstsagentpackage.azureedge.net/agent/2.153.1/vsts-agent-win-x64-2.153.1.zip' -Initialize -Validation string -Description 'Link to Azure DevOps/VSTS Build Agent'

# SCVMM
Set-PSFConfig -Module 'AutomatedLab' -Name SqlOdbc11 -Value 'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi'
Set-PSFConfig -Module 'AutomatedLab' -Name SqlOdbc13 -Value 'https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/x64/msodbcsql.msi'
Set-PSFConfig -Module 'AutomatedLab' -Name SqlCommandLineUtils -Value 'https://download.microsoft.com/download/C/8/8/C88C2E51-8D23-4301-9F4B-64C8E2F163C5/x64/MsSqlCmdLnUtils.msi'
Set-PSFConfig -Module 'AutomatedLab' -Name WindowsAdk -Value 'https://download.microsoft.com/download/8/6/c/86c218f3-4349-4aa5-beba-d05e48bbc286/adk/adksetup.exe'
Set-PSFConfig -Module 'AutomatedLab' -Name WindowsAdkPe -Value 'https://download.microsoft.com/download/3/c/2/3c2b23b2-96a0-452c-b9fd-6df72266e335/adkwinpeaddons/adkwinpesetup.exe'

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

# SharePoint
Set-PSFConfig -Module AutomatedLab -Name SharePoint2013Key -Value 'N3MDM-DXR3H-JD7QH-QKKCR-BY2Y7' -Validation String -Initialize -Description 'SP 2013 trial key'
Set-PSFConfig -Module AutomatedLab -Name SharePoint2016Key -Value 'NQGJR-63HC8-XCRQH-MYVCH-3J3QR' -Validation String -Initialize -Description 'SP 2016 trial key'
Set-PSFConfig -Module AutomatedLab -Name SharePoint2019Key -Value 'M692G-8N2JP-GG8B2-2W2P7-YY7J6' -Validation String -Initialize -Description 'SP 2019 trial key'

Set-PSFConfig -Module AutomatedLab -Name SharePoint2013Prerequisites -Value @(
    'https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
    "http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi",
    "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe",
    "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi",
    "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi",
    "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
    "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/r2/MicrosoftIdentityExtensions-64.msi",
    "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu",
    "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
    "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe"
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

Set-PSFConfig -Module AutomatedLab -Name SharePoint2016Prerequisites -Value @(
    "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi",
    "https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe",
    "https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/SyncSetup_en.x64.zip",
    "https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
    "https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi",
    "https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
    "https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe",
    'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi'
    'https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe'
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

Set-PSFConfig -Module AutomatedLab -Name SharePoint2019Prerequisites -Value @(
    "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi",
    "https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe",
    "https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/SyncSetup_en.x64.zip",
    "https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe",
    "https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi",
    "https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe",
    "https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe",
    'https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi'
    'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe'
) -Initialize -Description 'List of prerequisite urls for SP2013' -Validation stringarray

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
        Tfs2015 = @('Port','InitialCollection', 'DbServer')
        Tfs2017 = @('Port','InitialCollection', 'DbServer')
        Tfs2018 = @('Port','InitialCollection', 'DbServer')
        AzDevOps = @('Port','InitialCollection', 'DbServer','PAT','Organisation')
        TfsBuildWorker   = @(
            'NumberOfBuildWorkers'
            'TfsServer'
            'AgentPool'
            'PAT'
            'Organisation'
            'Capabilities'
        )
        WindowsAdminCenter = @('Port', 'EnableDevMode', 'ConnectedNode', 'UseSsl')
        Scvmm2016 = @(
            'MUOptIn'
            'SqlMachineName'
            'LibraryShareDescription'
            'UserName'
            'CompanyName'
            'IndigoHTTPSPort'
            'SQMOptIn'
            'TopContainerName'
            'SqlInstanceName'
            'RemoteDatabaseImpersonation'
            'LibraryShareName'
            'SqlDatabaseName'
            'VmmServiceLocalAccount'
            'IndigoNETTCPPort'
            'CreateNewLibraryShare'
            'WSManTcpPort'
            'IndigoHTTPPort'
            'ProductKey'
            'BitsTcpPort'
            'CreateNewSqlDatabase'
            'ProgramFiles'
            'LibrarySharePath'
            'IndigoTcpPort'
            'SkipServer'
        )
        Scvmm2019 = @(
            'MUOptIn'
            'SqlMachineName'
            'LibraryShareDescription'
            'UserName'
            'CompanyName'
            'IndigoHTTPSPort'
            'SQMOptIn'
            'TopContainerName'
            'SqlInstanceName'
            'RemoteDatabaseImpersonation'
            'LibraryShareName'
            'SqlDatabaseName'
            'VmmServiceLocalAccount'
            'IndigoNETTCPPort'
            'CreateNewLibraryShare'
            'WSManTcpPort'
            'IndigoHTTPPort'
            'ProductKey'
            'BitsTcpPort'
            'CreateNewSqlDatabase'
            'ProgramFiles'
            'LibrarySharePath'
            'IndigoTcpPort'
            'SkipServer'
        )
    }
    MandatoryRoleProperties = @{
        ADFSProxy = @(
            'AdfsFullName'
            'AdfsDomainName'
        )
    }
} -Initialize -Description 'Validation settings for lab validation. Please do not modify unless you know what you are doing.'

# Product key file path
$fPath = Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Assets/ProductKeys.xml'
$fcPath = Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Assets/ProductKeysCustom.xml'
Set-PSFConfig -Module AutomatedLab -Name ProductKeyFilePath -Value $fPath -Initialize -Validation string -Description 'Destination of the ProductKeys file for Windows products'
Set-PSFConfig -Module AutomatedLab -Name ProductKeyFilePathCustom -Value $fcPath -Initialize -Validation string -Description 'Destination of the ProductKeysCustom file for Windows products'

# LabSourcesLocation
# Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description 'Location of lab sources folder' -Validation string -Value ''

#endregion

#region Linux folder
if ($IsLinux -or $IsMacOs -and -not (Test-Path (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores')))
{
    $null = New-Item -ItemType Directory -Path (Join-Path -Path (Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot) -ChildPath 'Stores')
}
#endregion

#region ArgumentCompleter
Register-PSFTeppScriptblock -Name 'AutomatedLab-NotificationProviders' -ScriptBlock {
    (Get-PSFConfig -Module AutomatedLab -Name Notifications.NotificationProviders*).FullName | Foreach-Object { ($_ -split '\.')[3] } | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'AutomatedLab-OperatingSystem' -ScriptBlock {
    if (-not $global:AL_OperatingSystems)
    {
        $global:AL_OperatingSystems = Get-LabAvailableOperatingSystem -Path $labSources/ISOs -UseOnlyCache -NoDisplay
    }

    $global:AL_OperatingSystems.OperatingSystemName
}

Register-PSFTeppscriptblock -Name 'AutomatedLab-Labs' -ScriptBlock {
    $path = "$(Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot)/Labs"
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

Register-PSFTeppScriptblock -Name 'AutomatedLab-Subscription' -ScriptBlock {
    (Get-AzSubscription -WarningAction SilentlyContinue).Name
}

Register-PSFTeppArgumentCompleter -Command Add-LabMachineDefinition -Parameter Roles -Name 'AutomatedLab-Roles'
Register-PSFTeppArgumentCompleter -Command Get-Lab, Remove-Lab, Import-Lab -Parameter Name -Name 'AutomatedLab-Labs'
Register-PSFTeppArgumentCompleter -Command Connect-Lab -Parameter SourceLab, DestinationLab -Name 'AutomatedLab-Labs'
Register-PSFTeppArgumentCompleter -Command Send-ALNotification -Parameter Provider -Name "AutomatedLab-NotificationProviders"
Register-PSFTeppArgumentCompleter -Command Add-LabAzureSubscription -Parameter SubscriptionName -Name 'AutomatedLab-Subscription'
#endregion
