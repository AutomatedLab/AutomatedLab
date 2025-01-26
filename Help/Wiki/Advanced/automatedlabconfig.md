# The AutomatedLab settings system

Since AutomatedLab version 5 we are using user-specific and global settings, managed with the module [PSFramework](https://github.com/PowerShellFrameworkCollective/PSFramework).

To view all settings, you may use the `Get-LabConfigurationItem` cmdlet. For a bit of documentation, refer to `Get-PSFConfig -Module AutomatedLab` instead. If you don't know what a setting does, please do not set it. If you do know what the setting does, feel free to do so:  

```powershell
# One session only, then reset to default
Set-PSFConfig -Module AutomatedLab -Name MacAddressPrefix -Value '0017FC'

# Persistent setting, survives module updates
Set-PSFConfig -Module AutomatedLab -Name MacAddressPrefix -Value '0017FC' -PassThru | Register-PSFConfig
```

## Available settings

### AccessDatabaseEngine2016x86

Link to Access Database Engine (required for DSC Pull)

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/AccessDatabaseEngine.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.AccessDatabaseEngine2016x86 -Value <YourValue> -PassThru | Register-PSFConfig`


### AutoSyncLabSources

Toggle auto-sync of Azure lab sources in Azure labs

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.AutoSyncLabSources -Value <YourValue> -PassThru | Register-PSFConfig`


### AzureDisableLabSourcesStorage

Enable this setting to opt out of creating Lab Sources storage. This will prolong your lab deployment times significantly, if ISOs have to be mounted or large files have to be copied.

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.AzureDisableLabSourcesStorage -Value <YourValue> -PassThru | Register-PSFConfig`


### AzureDiskSkus

SKU for Azure VM Managed Disk, no UltraSSDs

Data type: System.Object[]  
Hidden?: False  
Default value: Standard_LRS Premium_LRS StandardSSD_LRS  

Set with: `Set-PSFConfig -FullName AutomatedLab.AzureDiskSkus -Value <YourValue> -PassThru | Register-PSFConfig`


### AzureEnableJit

Enable this setting to have AutomatedLab configure ports 22, 3389 and 5986 for JIT access. Can be done manually with Enable-LabAzureJitAccess and requested (after enabling) with Request-LabAzureJitAccess

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.AzureEnableJit -Value <YourValue> -PassThru | Register-PSFConfig`


### AzureLocationsUrls

Hashtable containing all Azure Speed Test URLs for automatic region placement

Data type: System.Collections.Hashtable  
Hidden?: False  
Default value: System.Collections.Hashtable  

Set with: `Set-PSFConfig -FullName AutomatedLab.AzureLocationsUrls -Value <YourValue> -PassThru | Register-PSFConfig`


### AzureRetryCount

The number of retries for Azure actions like creating a virtual network

Data type: System.Int32  
Hidden?: False  
Default value: 3  

Set with: `Set-PSFConfig -FullName AutomatedLab.AzureRetryCount -Value <YourValue> -PassThru | Register-PSFConfig`


### BuildAgentUri

Link to Azure DevOps/VSTS Build Agent

Data type: System.String  
Hidden?: False  
Default value: https://download.agent.dev.azure.com/agent/4.258.1/vsts-agent-win-x64-4.258.1.zip  

Set with: `Set-PSFConfig -FullName AutomatedLab.BuildAgentUri -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerUrl1902CB

Link to ConfigMgr 1902 CB

Data type: System.String  
Hidden?: False  
Default value: http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerUrl1902CB -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerUrl2002CB

Link to ConfigMgr 2002 CB

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/e/0/a/e0a2dd5e-2b96-47e7-9022-3030f8a1807b/MEM_Configmgr_2002.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerUrl2002CB -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerUrl2103CB

Link to ConfigMgr 2103 CB

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/8/8/8/888d525d-5523-46ba-aca8-4709f54affa8/MEM_Configmgr_2103.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerUrl2103CB -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerUrl2203CB

Link to ConfigMgr 2203 CB

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/f/5/5/f55e3b9c-781d-493b-932b-16aa1b2f6371/MEM_Configmgr_2203.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerUrl2203CB -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerUrl2411TP

Link to ConfigMgr 2411 TP

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/ConfigMgr_TechPreview2411.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerUrl2411TP -Value <YourValue> -PassThru | Register-PSFConfig`


### ConfigurationManagerWmiExplorer

Link to WMI explorer

Data type: System.String  
Hidden?: False  
Default value: https://github.com/vinaypamnani/wmie2/releases/download/v2.0.0.2/WmiExplorer_2.0.0.2.zip  

Set with: `Set-PSFConfig -FullName AutomatedLab.ConfigurationManagerWmiExplorer -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist32_2012

Link to VC++ redist 2012 (x86)

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist32_2012 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist32_2013

Link to VC++ redist 2013 (x86)

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/highdpimfc2013x86enu  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist32_2013 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist32_2015

Link to VC++ redist 2015 (x86)

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x86.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist32_2015 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist32_2017

Link to VC++ redist 2017 (x86)

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/vs/15/release/vc_redist.x86.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist32_2017 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist64_2010

Link to VC++ redist 2010 (x64)

Data type: System.String  
Hidden?: False  
Default value: http://go.microsoft.com/fwlink/?LinkId=404264&clcid=0x409  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist64_2010 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist64_2012

Link to VC++ redist 2012 (x64)

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist64_2012 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist64_2013

Link to VC++ redist 2013 (x64)

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/highdpimfc2013x64enu  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist64_2013 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist64_2015

Link to VC++ redist 2015 (x64)

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6/A/A/6AA4EDFF-645B-48C5-81CC-ED5963AEAD48/vc_redist.x64.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist64_2015 -Value <YourValue> -PassThru | Register-PSFConfig`


### cppredist64_2017

Link to VC++ redist 2017 (x64)

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/vs/15/release/vc_redist.x64.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.cppredist64_2017 -Value <YourValue> -PassThru | Register-PSFConfig`


### CreateOnlyReferencedDisks

Disks that are not references by a VM will not be created

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.CreateOnlyReferencedDisks -Value <YourValue> -PassThru | Register-PSFConfig`


### DefaultAddressSpace

Default address space if no address space is selected

Data type: System.String  
Hidden?: False  
Default value: 192.168.10.0/24  

Set with: `Set-PSFConfig -FullName AutomatedLab.DefaultAddressSpace -Value <YourValue> -PassThru | Register-PSFConfig`


### DefaultAzureRoleSize

The default Azure role size, e.g. from Get-LabAzureAvailableRoleSize

Data type: System.String  
Hidden?: False  
Default value: D  

Set with: `Set-PSFConfig -FullName AutomatedLab.DefaultAzureRoleSize -Value <YourValue> -PassThru | Register-PSFConfig`


### DefaultDnsForwarder1

If routing is installed on a Root DC, this forwarder is used

Data type: System.String  
Hidden?: False  
Default value: 1.1.1.1  

Set with: `Set-PSFConfig -FullName AutomatedLab.DefaultDnsForwarder1 -Value <YourValue> -PassThru | Register-PSFConfig`


### DefaultDnsForwarder2

If routing is installed on a Root DC, this forwarder is used

Data type: System.String  
Hidden?: False  
Default value: 8.8.8.8  

Set with: `Set-PSFConfig -FullName AutomatedLab.DefaultDnsForwarder2 -Value <YourValue> -PassThru | Register-PSFConfig`


### DefaultProgressIndicator

After how many minutes will a progress indicator be written

Data type: System.Int32  
Hidden?: False  
Default value: 10  

Set with: `Set-PSFConfig -FullName AutomatedLab.DefaultProgressIndicator -Value <YourValue> -PassThru | Register-PSFConfig`


### DisableClusterCheck

Set to true to disable checking cluster with Get-LWHyperVVM in case you are suffering from performance issues. Caution: While this speeds up deployment, the likelihood for errors increases when machines are migrated away from the host!

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DisableClusterCheck -Value <YourValue> -PassThru | Register-PSFConfig`


### DisableConnectivityCheck

Indicates whether connectivity checks should be skipped. Certain systems like Azure DevOps build workers do not send ICMP packges and the method might always fail

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DisableConnectivityCheck -Value <YourValue> -PassThru | Register-PSFConfig`


### DisableDeviceNaming

Disables Device Naming for VM NICs. Enabled by default for Hosts > 2016 and Gen 2 Guests > 2016

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DisableDeviceNaming -Value <YourValue> -PassThru | Register-PSFConfig`


### DisableVersionCheck

Set to true to skip checking GitHub for an updated AutomatedLab release

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DisableVersionCheck -Value <YourValue> -PassThru | Register-PSFConfig`


### DisableWindowsDefender

Indicates that Windows Defender should be disabled on the lab VMs

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.DisableWindowsDefender -Value <YourValue> -PassThru | Register-PSFConfig`


### DiskDeploymentInProgressPath

The file indicating that Hyper-V disks are being configured to reduce disk congestion

Data type: System.Management.Automation.PSObject  
Hidden?: False  
Default value: $HOME/.automatedlab/LabDiskDeploymentInProgress.txt  

Set with: `Set-PSFConfig -FullName AutomatedLab.DiskDeploymentInProgressPath -Value <YourValue> -PassThru | Register-PSFConfig`


### DiskFileName

The file name for the deserialized disks. Do not change unless you know what you are doing.

Data type: System.String  
Hidden?: False  
Default value: Disks.xml  

Set with: `Set-PSFConfig -FullName AutomatedLab.DiskFileName -Value <YourValue> -PassThru | Register-PSFConfig`


### DoNotAddVmsToCluster

Set to true to skip adding VMs to a cluster if AutomatedLab is being run on a cluster node

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DoNotAddVmsToCluster -Value <YourValue> -PassThru | Register-PSFConfig`


### DoNotPrompt

Indicates that AutomatedLab should not display prompts. Workaround for environments that register as interactive, even if they are not. Skips enabling telemetry, skips Azure lab sources sync, forcibly configures remoting

Data type: System.Boolean  
Hidden?: True  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DoNotPrompt -Value <YourValue> -PassThru | Register-PSFConfig`


### DoNotSkipNonNonEnglishIso

Indicates that non English ISO files will not be skipped

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DoNotSkipNonNonEnglishIso -Value <YourValue> -PassThru | Register-PSFConfig`


### DoNotUseGetHostEntryInNewLabPSSession

Do not use hosts file for session creation

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.DoNotUseGetHostEntryInNewLabPSSession -Value <YourValue> -PassThru | Register-PSFConfig`


### DoNotWaitForLinux

Indicates that you will not wait for Linux VMs to be ready, e.g. because you are offline and PowerShell cannot be installed.

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.DoNotWaitForLinux -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet452DownloadLink

Link to .NET 4.5.2

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet452DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet462DownloadLink

Link to .NET 4.6.2

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP462-KB3151800-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet462DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet46DownloadLink

Link to .NET 4.6

Data type: System.String  
Hidden?: False  
Default value: http://download.microsoft.com/download/6/F/9/6F9673B1-87D1-46C4-BF04-95F24C3EB9DA/enu_netfx/NDP46-KB3045557-x86-x64-AllOS-ENU_exe/NDP46-KB3045557-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet46DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet471DownloadLink

Link to .NET 4.7.1

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP471-KB4033342-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet471DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet472DownloadLink

Link to .NET 4.7.2

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP472-KB4054530-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet472DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### dotnet48DownloadLink

Link to .NET 4.8

Data type: System.String  
Hidden?: False  
Default value: https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.dotnet48DownloadLink -Value <YourValue> -PassThru | Register-PSFConfig`


### DscMofPath

Default path for MOF files on Pull server

Data type: System.String  
Hidden?: False  
Default value: DscConfigurations  

Set with: `Set-PSFConfig -FullName AutomatedLab.DscMofPath -Value <YourValue> -PassThru | Register-PSFConfig`


### DscPullServerRegistrationKey

DSC registration key used on all Dsc Pull servers and clients

Data type: System.String  
Hidden?: False  
Default value: ec717ee9-b343-49ee-98a2-26e53939eecf  

Set with: `Set-PSFConfig -FullName AutomatedLab.DscPullServerRegistrationKey -Value <YourValue> -PassThru | Register-PSFConfig`


### Dynamics365Uri

Dynamics 365 Download URI, defaults to CRM9.0

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/B/D/0/BD0FA814-9885-422A-BA0E-54CBB98C8A33/CRM9.0-Server-ENU-amd64.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.Dynamics365Uri -Value <YourValue> -PassThru | Register-PSFConfig`


### Exchange2013DownloadUrl

Download url for Exchange Server 2013 exe

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/7/F/D/7FDCC96C-26C0-4D49-B5DB-5A8B36935903/Exchange2013-x64-cu23.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.Exchange2013DownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### Exchange2016DownloadUrl

Download url for Exchange Server 2016 ISO

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/8/d/2/8d2d01b4-5bbb-4726-87da-0e331bc2b76f/ExchangeServer2016-x64-CU23.ISO  

Set with: `Set-PSFConfig -FullName AutomatedLab.Exchange2016DownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### Exchange2019DownloadUrl

Download url for Exchange Server 2019 ISO

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/b/c/7/bc766694-8398-4258-8e1e-ce4ddb9b3f7d/ExchangeServer2019-x64-CU12.ISO  

Set with: `Set-PSFConfig -FullName AutomatedLab.Exchange2019DownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### IisUrlRewriteDownloadUrl

Link to IIS URL Rewrite Module needed for Exchange 2016 and 2019

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi  

Set with: `Set-PSFConfig -FullName automatedlab.IisUrlRewriteDownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### InvokeLabCommandRetries

Number of retries for Invoke-LabCommand

Data type: System.Int32  
Hidden?: False  
Default value: 3  

Set with: `Set-PSFConfig -FullName AutomatedLab.InvokeLabCommandRetries -Value <YourValue> -PassThru | Register-PSFConfig`


### InvokeLabCommandRetryIntervalInSeconds

Retry interval for Invoke-LabCommand

Data type: System.Int32  
Hidden?: False  
Default value: 10  

Set with: `Set-PSFConfig -FullName AutomatedLab.InvokeLabCommandRetryIntervalInSeconds -Value <YourValue> -PassThru | Register-PSFConfig`


### LabAppDataRoot

Root folder to Labs, Assets and Stores

Data type: System.Management.Automation.PSObject  
Hidden?: False  
Default value: $HOME/.automatedlab  

Set with: `Set-PSFConfig -FullName AutomatedLab.LabAppDataRoot -Value <YourValue> -PassThru | Register-PSFConfig`


### LabFileName

The file name for the deserialized labs. Do not change unless you know what you are doing.

Data type: System.String  
Hidden?: False  
Default value: Lab.xml  

Set with: `Set-PSFConfig -FullName AutomatedLab.LabFileName -Value <YourValue> -PassThru | Register-PSFConfig`


### LabSourcesLocation



Data type: System.String  
Hidden?: False  
Default value:  

Set with: `Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value <YourValue> -PassThru | Register-PSFConfig`


### LabSourcesMaxFileSizeMb

The default file size for Sync-LabAzureLabSources

Data type: System.Int32  
Hidden?: False  
Default value: 50  

Set with: `Set-PSFConfig -FullName AutomatedLab.LabSourcesMaxFileSizeMb -Value <YourValue> -PassThru | Register-PSFConfig`


### LabSourcesSyncIntervalDays

Interval in days for lab sources auto-sync

Data type: System.Int32  
Hidden?: False  
Default value: 60  

Set with: `Set-PSFConfig -FullName AutomatedLab.LabSourcesSyncIntervalDays -Value <YourValue> -PassThru | Register-PSFConfig`


### MacAddressPrefix

The MAC address prefix for Hyper-V labs

Data type: System.String  
Hidden?: False  
Default value: 0017FB  

Set with: `Set-PSFConfig -FullName AutomatedLab.MacAddressPrefix -Value <YourValue> -PassThru | Register-PSFConfig`


### MachineFileName

The file name for the deserialized machines. Do not change unless you know what you are doing.

Data type: System.String  
Hidden?: False  
Default value: Machines.xml  

Set with: `Set-PSFConfig -FullName AutomatedLab.MachineFileName -Value <YourValue> -PassThru | Register-PSFConfig`


### MaxPSSessionsPerVM

Maximum number of sessions per VM

Data type: System.Int32  
Hidden?: False  
Default value: 5  

Set with: `Set-PSFConfig -FullName AutomatedLab.MaxPSSessionsPerVM -Value <YourValue> -PassThru | Register-PSFConfig`


### MinimumAzureModuleVersion

The minimum expected Azure module version

Data type: System.String  
Hidden?: False  
Default value: 4.1.0  

Set with: `Set-PSFConfig -FullName AutomatedLab.MinimumAzureModuleVersion -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Ifttt.EventName

IFTTT Event Name

Data type: System.String  
Hidden?: False  
Default value: The name of your IFTTT event  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Ifttt.EventName -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Ifttt.Key

IFTTT Key Name

Data type: System.String  
Hidden?: False  
Default value: Your IFTTT key here  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Ifttt.Key -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.CC

A list of default CC recipients

Data type: System.Object[]  
Hidden?: False  
Default value: Recipients here  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.CC -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.From

Your sender address

Data type: System.String  
Hidden?: False  
Default value: @localhost  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.From -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.Port

Port of your SMTP Server

Data type: System.Int32  
Hidden?: False  
Default value: 25  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.Port -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.Priority

Priority of your message

Data type: System.String  
Hidden?: False  
Default value: Normal  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.Priority -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.SmtpServer

Adress of your SMTP server

Data type: System.String  
Hidden?: False  
Default value: your SMTP server here  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.SmtpServer -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Mail.To

A list of default recipients

Data type: System.Object[]  
Hidden?: False  
Default value: Recipients here  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Mail.To -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Toast.Image

The image for your toast notification

Data type: System.String  
Hidden?: False  
Default value: https://raw.githubusercontent.com/AutomatedLab/AutomatedLab/master/Assets/Automated-Lab_icon512.png  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Toast.Image -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Voice.Culture

Voice culture, needs to be available and defaults to en-us

Data type: System.String  
Hidden?: False  
Default value: en-us  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Voice.Culture -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.NotificationProviders.Voice.Gender

Gender of voice to use

Data type: System.String  
Hidden?: False  
Default value: female  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.NotificationProviders.Voice.Gender -Value <YourValue> -PassThru | Register-PSFConfig`


### Notifications.SubscribedProviders

List of subscribed providers

Data type: System.Object[]  
Hidden?: False  
Default value: Toast  

Set with: `Set-PSFConfig -FullName AutomatedLab.Notifications.SubscribedProviders -Value <YourValue> -PassThru | Register-PSFConfig`


### OfficeDeploymentTool

Link to Microsoft Office deployment tool

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18827-20140.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.OfficeDeploymentTool -Value <YourValue> -PassThru | Register-PSFConfig`


### OpenSshUri

Link to OpenSSH binaries

Data type: System.String  
Hidden?: False  
Default value: https://github.com/PowerShell/Win32-OpenSSH/releases/download/v7.6.0.0p1-Beta/OpenSSH-Win64.zip  

Set with: `Set-PSFConfig -FullName AutomatedLab.OpenSshUri -Value <YourValue> -PassThru | Register-PSFConfig`


### OsRoot

Host operating system root, used mostly with file transfers. Do not modify if not requried.

Data type: System.String  
Hidden?: True  
Default value: /  

Set with: `Set-PSFConfig -FullName AutomatedLab.OsRoot -Value <YourValue> -PassThru | Register-PSFConfig`


### OverridePowerPlan

On Windows: Indicates that power settings will be set to High Power during lab deployment

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.OverridePowerPlan -Value <YourValue> -PassThru | Register-PSFConfig`


### ProductKeyFilePath

Destination of the ProductKeys file for Windows products

Data type: System.Management.Automation.PSObject  
Hidden?: False  
Default value: $HOME/.automatedlab/Assets/ProductKeys.xml  

Set with: `Set-PSFConfig -FullName AutomatedLab.ProductKeyFilePath -Value <YourValue> -PassThru | Register-PSFConfig`


### ProductKeyFilePathCustom

Destination of the ProductKeysCustom file for Windows products

Data type: System.Management.Automation.PSObject  
Hidden?: False  
Default value: $HOME/.automatedlab/Assets/ProductKeysCustom.xml  

Set with: `Set-PSFConfig -FullName AutomatedLab.ProductKeyFilePathCustom -Value <YourValue> -PassThru | Register-PSFConfig`


### ReportViewer2015

SQL Server Report Viewer 2015

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/A/1/2/A129F694-233C-4C7C-860F-F73139CF2E01/ENU/x86/ReportViewer.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.ReportViewer2015 -Value <YourValue> -PassThru | Register-PSFConfig`


### RequiredAzModules

Required Az modules

Data type: System.Object[]  
Hidden?: False  
Default value: System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable  

Set with: `Set-PSFConfig -FullName AutomatedLab.RequiredAzModules -Value <YourValue> -PassThru | Register-PSFConfig`


### RequiredAzStackModules

Required Az Stack Hub modules

Data type: System.Object[]  
Hidden?: False  
Default value: System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable System.Collections.Hashtable  

Set with: `Set-PSFConfig -FullName AutomatedLab.RequiredAzStackModules -Value <YourValue> -PassThru | Register-PSFConfig`


### SendFunctionTelemetry

Indicates if function call telemetry is sent

Data type: System.Boolean  
Hidden?: True  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.SendFunctionTelemetry -Value <YourValue> -PassThru | Register-PSFConfig`


### SetLocalIntranetSites

All, Forest, Domain, None

Data type: System.String  
Hidden?: False  
Default value: All  

Set with: `Set-PSFConfig -FullName AutomatedLab.SetLocalIntranetSites -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2013Key

SP 2013 trial key

Data type: System.String  
Hidden?: False  
Default value: N3MDM-DXR3H-JD7QH-QKKCR-BY2Y7  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2013Key -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2013Prerequisites

List of prerequisite urls for SP2013

Data type: System.Object[]  
Hidden?: False  
Default value: https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/r2/MicrosoftIdentityExtensions-64.msi http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2013Prerequisites -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2016Key

SP 2016 trial key

Data type: System.String  
Hidden?: False  
Default value: NQGJR-63HC8-XCRQH-MYVCH-3J3QR  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2016Key -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2016Prerequisites

List of prerequisite urls for SP2013

Data type: System.Object[]  
Hidden?: False  
Default value: https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe https://download.microsoft.com/download/B/9/D/B9D6E014-C949-4A1E-BA6B-2E0DEBA23E54/SyncSetup_en.x64.zip https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi https://download.microsoft.com/download/8/b/7/8b79adc2-162c-4cf4-a200-3aeaadc455bf/NDP462-KB3151800-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2016Prerequisites -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2019Key

SP 2019 trial key

Data type: System.String  
Hidden?: False  
Default value: M692G-8N2JP-GG8B2-2W2P7-YY7J6  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2019Key -Value <YourValue> -PassThru | Register-PSFConfig`


### SharePoint2019Prerequisites

List of prerequisite urls for SP2013

Data type: System.Object[]  
Hidden?: False  
Default value: https://download.microsoft.com/download/F/3/C/F3C64941-22A0-47E9-BC9B-1A19B4CA3E88/ENU/x64/sqlncli.msi https://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe https://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi https://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe https://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi https://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe https://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi https://download.microsoft.com/download/f/3/a/f3a6af84-da23-40a5-8d1c-49cc10c8e76f/NDP472-KB4054530-x86-x64-AllOS-ENU.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.SharePoint2019Prerequisites -Value <YourValue> -PassThru | Register-PSFConfig`


### SkipHostFileModification

Indicates that the hosts file should not be modified when deploying a new lab.

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.SkipHostFileModification -Value <YourValue> -PassThru | Register-PSFConfig`


### SkipSysInternals

Set to true to skip downloading Sysinternals

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.SkipSysInternals -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2016ManagementStudio

Link to SSMS 2016

Data type: System.String  
Hidden?: False  
Default value: https://go.microsoft.com/fwlink/?LinkID=840946  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2016ManagementStudio -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2017ManagementStudio

Link to SSMS 2017 18.2

Data type: System.String  
Hidden?: False  
Default value: https://go.microsoft.com/fwlink/?linkid=2099720  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2017ManagementStudio -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2017SSRS

Download link to SSRS 2017

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2017SSRS -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2019ManagementStudio

Link to SSMS latest

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/ssmsfullsetup  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2019ManagementStudio -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2019SSRS

Download link to SSRS 2019

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2019SSRS -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2022ManagementStudio

Link to SSMS latest

Data type: System.String  
Hidden?: False  
Default value: https://aka.ms/ssmsfullsetup  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2022ManagementStudio -Value <YourValue> -PassThru | Register-PSFConfig`


### Sql2022SSRS

Download link to SSRS 2022

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/8/3/2/832616ff-af64-42b5-a0b1-5eb07f71dec9/SQLServerReportingServices.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.Sql2022SSRS -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlClrType2014

Download link to SQL Server Clr Types v2014, used with SCOM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6/7/8/67858AF1-B1B3-48B1-87C4-4483503E71DC/ENU/x64/SQLSysClrTypes.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlClrType2014 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlClrType2016

Download link to SQL Server Clr Types v2016, used with SCOM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6/4/5/645B2661-ABE3-41A4-BC2D-34D9A10DD303/ENU/x64/SQLSysClrTypes.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlClrType2016 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlClrType2019

Download link to SQL Server Clr Types v2019, used with SCOM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/d/d/1/dd194c5c-d859-49b8-ad64-5cbdcbb9b7bd/SQLSysClrTypes.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlClrType2019 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlCommandLineUtils

Download Link for SQL Commandline Utils, used with SCVMM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/C/8/8/C88C2E51-8D23-4301-9F4B-64C8E2F163C5/x64/MsSqlCmdLnUtils.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlCommandLineUtils -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlOdbc11

Download Link for SQL ODBC Driver 11, used with SCVMM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlOdbc11 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlOdbc13

Download Link for SQL ODBC Driver 13, used with SCVMM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/x64/msodbcsql.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlOdbc13 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2012

Link to SQL sample DB for SQL 2012

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2012 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2014

Link to SQL sample DB for SQL 2014

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2014.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2014 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2016

Link to SQL sample DB for SQL 2016

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2016 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2017

Link to SQL sample DB for SQL 2017

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2017 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2019

Link to SQL sample DB for SQL 2019

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2019 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2022

Link to SQL sample DB for SQL 2022

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2022 -Value <YourValue> -PassThru | Register-PSFConfig`


### SQLServer2025

Link to SQL sample DB for SQL 2025

Data type: System.String  
Hidden?: False  
Default value: https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak  

Set with: `Set-PSFConfig -FullName AutomatedLab.SQLServer2025 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlServerNativeClient2012

Download link to SQL Native Client v2012, used with Dynamics and ConfigMgr

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlServerNativeClient2012 -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlServerReportBuilder

Download link to SQL Server Report Builder

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/5/E/B/5EB40744-DC0A-47C0-8B0A-1830E74D3C23/ReportBuilder.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlServerReportBuilder -Value <YourValue> -PassThru | Register-PSFConfig`


### SqlSmo2016

Download link to SQL Server Share Management Objects v2016, used with Dynamics

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/6/4/5/645B2661-ABE3-41A4-BC2D-34D9A10DD303/ENU/x64/SharedManagementObjects.msi  

Set with: `Set-PSFConfig -FullName AutomatedLab.SqlSmo2016 -Value <YourValue> -PassThru | Register-PSFConfig`


### SupportGen2VMs

Indicates that Gen2 VMs are supported

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.SupportGen2VMs -Value <YourValue> -PassThru | Register-PSFConfig`


### SwitchDeploymentInProgressPath

The file indicating that VM switches are being deployed in case multiple lab deployments are started in parallel

Data type: System.Management.Automation.PSObject  
Hidden?: False  
Default value: $HOME/.automatedlab/VSwitchDeploymentInProgress.txt  

Set with: `Set-PSFConfig -FullName AutomatedLab.SwitchDeploymentInProgressPath -Value <YourValue> -PassThru | Register-PSFConfig`


### SysInternalsDownloadUrl

Link to download of SysInternals

Data type: System.String  
Hidden?: False  
Default value: https://download.sysinternals.com/files/SysinternalsSuite.zip  

Set with: `Set-PSFConfig -FullName AutomatedLab.SysInternalsDownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### SysInternalsUrl

Link to SysInternals to check for newer versions

Data type: System.String  
Hidden?: False  
Default value: https://technet.microsoft.com/en-us/sysinternals/bb842062  

Set with: `Set-PSFConfig -FullName AutomatedLab.SysInternalsUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_ConfigurationManagerInstallation

Timeout in minutes to wait for the installation of Configuration Manager. Default value 60.

Data type: System.Int32  
Hidden?: False  
Default value: 60  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_ConfigurationManagerInstallation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_DcPromotionAdwsReady

Timeout in minutes for availability of ADWS after DC Promo

Data type: System.Int32  
Hidden?: False  
Default value: 20  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_DcPromotionAdwsReady -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_DcPromotionRestartAfterDcpromo

Timeout in minutes for restart after DC Promo

Data type: System.Int32  
Hidden?: False  
Default value: 60  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_DcPromotionRestartAfterDcpromo -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_InstallLabCAInstallation

Timeout in minutes for CA setup

Data type: System.Int32  
Hidden?: False  
Default value: 40  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_InstallLabCAInstallation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_RestartLabMachine_Shutdown

Timeout in minutes for Restart-LabVm

Data type: System.Int32  
Hidden?: False  
Default value: 30  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_RestartLabMachine_Shutdown -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_Sql2008Installation

Timeout in minutes for SQL 2008

Data type: System.Int32  
Hidden?: False  
Default value: 90  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_Sql2008Installation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_Sql2012Installation

Timeout in minutes for SQL 2012

Data type: System.Int32  
Hidden?: False  
Default value: 90  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_Sql2012Installation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_Sql2014Installation

Timeout in minutes for SQL 2014

Data type: System.Int32  
Hidden?: False  
Default value: 90  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_Sql2014Installation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_StartLabMachine_Online

Timeout in minutes for Start-LabVm

Data type: System.Int32  
Hidden?: False  
Default value: 60  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_StartLabMachine_Online -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_StopLabMachine_Shutdown

Timeout in minutes for Stop-LabVm

Data type: System.Int32  
Hidden?: False  
Default value: 30  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_StopLabMachine_Shutdown -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_TestPortInSeconds

Timeout in seconds for Test-Port

Data type: System.Int32  
Hidden?: False  
Default value: 2  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_TestPortInSeconds -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_VisualStudio2013Installation

Timeout in minutes for VS 2013

Data type: System.Int32  
Hidden?: False  
Default value: 90  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_VisualStudio2013Installation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_VisualStudio2015Installation

Timeout in minutes for VS 2015

Data type: System.Int32  
Hidden?: False  
Default value: 90  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_VisualStudio2015Installation -Value <YourValue> -PassThru | Register-PSFConfig`


### Timeout_WaitLabMachine_Online

Timeout in minutes for Wait-LabVm

Data type: System.Int32  
Hidden?: False  
Default value: 60  

Set with: `Set-PSFConfig -FullName AutomatedLab.Timeout_WaitLabMachine_Online -Value <YourValue> -PassThru | Register-PSFConfig`


### UseLatestAzureProviderApi

Indicates that the latest provider API versions available in the labs region should be used

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.UseLatestAzureProviderApi -Value <YourValue> -PassThru | Register-PSFConfig`


### ValidationSettings

Validation settings for lab validation. Please do not modify unless you know what you are doing.

Data type: System.Collections.Hashtable  
Hidden?: False  
Default value: System.Collections.Hashtable  

Set with: `Set-PSFConfig -FullName AutomatedLab.ValidationSettings -Value <YourValue> -PassThru | Register-PSFConfig`


### VMConnectDesktopSize

The default resolution for Hyper-V's VMConnect.exe

Data type: System.String  
Hidden?: False  
Default value: 1366, 768  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMConnectDesktopSize -Value <YourValue> -PassThru | Register-PSFConfig`


### VMConnectFullScreen

Enable full screen mode for VMConnect.exe

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMConnectFullScreen -Value <YourValue> -PassThru | Register-PSFConfig`


### VMConnectRedirectedDrives

Drives to mount in a VMConnect session. Use '*' for all drives or a semicolon seperated list.

Data type: System.String  
Hidden?: False  
Default value: none  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMConnectRedirectedDrives -Value <YourValue> -PassThru | Register-PSFConfig`


### VMConnectUseAllMonitors

Use all monitors for VMConnect.exe

Data type: System.Boolean  
Hidden?: False  
Default value: False  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMConnectUseAllMonitors -Value <YourValue> -PassThru | Register-PSFConfig`


### VMConnectWriteConfigFile

Enable the writing of VMConnect config files by default

Data type: System.Boolean  
Hidden?: False  
Default value: True  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMConnectWriteConfigFile -Value <YourValue> -PassThru | Register-PSFConfig`


### VMDeploymentFilesFolder

Folder local to each VM which contains temporary files during deployment, logs and such. Will use ExecutionContext.InvokeCommand.ExpandString() to ensure xplat capabilities.

Data type: System.String  
Hidden?: False  
Default value: $([Environment]::GetFolderPath('ApplicationData'))/DeployDebug  

Set with: `Set-PSFConfig -FullName AutomatedLab.VMDeploymentFilesFolder -Value <YourValue> -PassThru | Register-PSFConfig`


### VmPath

VM storage location

Data type:   
Hidden?: False  
Default value:   

Set with: `Set-PSFConfig -FullName AutomatedLab.VmPath -Value <YourValue> -PassThru | Register-PSFConfig`


### WacDownloadUrl

Windows Admin Center Download URL

Data type: System.String  
Hidden?: False  
Default value: http://aka.ms/WACDownload  

Set with: `Set-PSFConfig -FullName AutomatedLab.WacDownloadUrl -Value <YourValue> -PassThru | Register-PSFConfig`


### WacMsIntermediateCaCert

Windows Admin Center Code-Signing Cert Intermediate CA cert URL

Data type: System.String  
Hidden?: False  
Default value: https://www.microsoft.com/pkiops/certs/MicCodSigPCA2011_2011-07-08.crt  

Set with: `Set-PSFConfig -FullName AutomatedLab.WacMsIntermediateCaCert -Value <YourValue> -PassThru | Register-PSFConfig`


### WindowsAdk

Download Link for Windows ADK, used with SCVMM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/2/d/9/2d9c8902-3fcd-48a6-a22a-432b08bed61e/ADK/adksetup.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.WindowsAdk -Value <YourValue> -PassThru | Register-PSFConfig`


### WindowsAdkPe

Download Link for Windows ADK PE, used with SCVMM

Data type: System.String  
Hidden?: False  
Default value: https://download.microsoft.com/download/5/5/6/556e01ec-9d78-417d-b1e1-d83a2eff20bc/ADKWinPEAddons/adkwinpesetup.exe  

Set with: `Set-PSFConfig -FullName AutomatedLab.WindowsAdkPe -Value <YourValue> -PassThru | Register-PSFConfig`


### WinRmMaxConcurrentOperationsPerUser

CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different number of per-user concurrent operations on all lab machines if necessary.

Data type: System.Int32  
Hidden?: False  
Default value: 1500  

Set with: `Set-PSFConfig -FullName AutomatedLab.WinRmMaxConcurrentOperationsPerUser -Value <YourValue> -PassThru | Register-PSFConfig`


### WinRmMaxConnections

CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different max number of connections on all lab machines if necessary.

Data type: System.Int32  
Hidden?: False  
Default value: 300  

Set with: `Set-PSFConfig -FullName AutomatedLab.WinRmMaxConnections -Value <YourValue> -PassThru | Register-PSFConfig`


### WinRmMaxEnvelopeSizeKb

CAREFUL! Fiddling with the defaults will likely result in errors if you do not know what you are doing! Configure a different envelope size on all lab machines if necessary.

Data type: System.Int32  
Hidden?: False  
Default value: 500  

Set with: `Set-PSFConfig -FullName AutomatedLab.WinRmMaxEnvelopeSizeKb -Value <YourValue> -PassThru | Register-PSFConfig`

