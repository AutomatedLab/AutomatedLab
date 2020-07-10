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

The URL to download the Microsoft Access database engine used with our Pull Server role.

### AzureLocationsUrls

This setting contains key value pairs containing the Azure region name and the speed test URL assigned to it to automatically select the appropriate region for a new lab deployment.

### AzureRetryCount

In integer indicating how often Azure cmdlets should be executed again if a transient error occurs.

### BuildAgentUri

The URL to download the TFS/VSTS/Azure DevOps build agent.

### cppredist32

The URL to the Visual C++ redist (x86)

### cppredist64

The URL to the Visual C++ redist

### DefaultAddressSpace

The default address space for a lab, e.g. 192.168.10.0/24

### DefaultAzureRoleSize

The default Azure VM role size class to use, e.g. D. AutomatedLab tries to find the next best role size fitting your VM processor and memory requirements.

### DefaultProgressIndicator



### DisableWindowsDefender

Indicates if Windows Defender should be disabled for new VM deployments.

### DiskDeploymentInProgressPath

The path where the temporary file indicating that disks are created is stored. This setting is used to lessen the load on a disk during deployments.

### DiskFileName

The name of the XML file containing disk configurations of a lab.

### DoNotSkipNonNonEnglishIso

Indicates that non English ISO files should not be skipped during import.

### DoNotUseGetHostEntryInNewLabPSSession

Indicates that the hosts file should not be used to lookup the DNS name of a lab VM.

### dotnet452DownloadLink

The URL to download .NET 4.5.2

### dotnet462DownloadLink

The URL to download .NET 4.6.2

### dotnet46DownloadLink

The URL to download .NET 4.6.1

### dotnet471DownloadLink

The URL to download .NET 4.7.1

### DscMofPath

The location where lab DSC MOF files should be stored, e.g. when using the cmdlet ```Invoke-LabDscConfiguration```

### InvokeLabCommandRetries

How many times should ```Invoke-LabCommand``` be rerun if a terminating error occurs?

### InvokeLabCommandRetryIntervalInSeconds

How much time should elapse between the retries of ```Invoke-LabCommand```?

### LabFileName

The name of the lab XML configuration file.

### Logging

This key contains logging options:  
- TruncateLength: How long can a line be?
- TruncateTypes: Which .NET types should be truncated?
- DefaultFolder: The default log folder
- DefaultName: The default log prefix
- Level: The minimum level to log
- Silent: Log Write-* cmdlets without showing their streams.
- AutoStart: Automatically start logging as soon as a Write-* cmdlet is used

### MachineFileName

The machine definition file for a lab.

### MaxPSSessionsPerVM

The maximum number of WinRM session for each lab VM

### MemoryWeight_CARoot
### MemoryWeight_CASubordinate
### MemoryWeight_ConfigManager
### MemoryWeight_DC
### MemoryWeight_DevTools
### MemoryWeight_ExchangeServer
### MemoryWeight_FileServer
### MemoryWeight_FirstChildDC
### MemoryWeight_OpsMgr
### MemoryWeight_Orchestrator
### MemoryWeight_RootDC
### MemoryWeight_SQLServer2012
### MemoryWeight_SQLServer2014
### MemoryWeight_WebServer

### MinimumAzureModuleVersion

The minimum version of Azure modules required to run. Do not change this to a lower setting, errors will certainly occur.

### NotificationProviders

This setting controls which notifications to display:
- NotificationProviders: Contains all provider-specific settings
  - Ifttt: Specify key and eventname to trigger an event on IFTTT
  - Mail: Specify port, server, to, from, prio and CC
  - Toast: Use a different image file for your Toast. Will be downloaded with Get-LabInternetFile.
  - Voice: Control voice settings to use. If a culture is selected, ensure that the voice pack is installed. Otherwise reverts to English.

### OfficeDeploymentTool

### OpenSshUri

Not currently in use: The URL to download OpenSsh from if the binary cannot be found.

### SetLocalIntranetSites


### Sql2016ManagementStudio

The download link to SSMS 2016

### Sql2017ManagementStudio

The download link to SSMS 2017

### SQLServer2008

The sample database for SQL Server 2008

### SQLServer2008R2

The sample database for SQL Server 2008 R2


### SQLServer2012

The sample database for SQL Server 2012


### SQLServer2014

The sample database for SQL Server 2014


### SQLServer2016

The sample database for SQL Server 2016


### SQLServer2017

The sample database for SQL Server 2017

### SQLServer2019

The sample database for SQL Server 2019


### SubscribedProviders

The subscribed notification providers to use.

### SupportGen2VMs

Indicates that AutomatedLab should use Gen2 Hyper-V VMs

### SysInternalsDownloadUrl

The URL to download the current version of the SysInternals suite.

### SysInternalsUrl

The URL to check for the current version of the SysInternals Suite.

### Timeout_DcPromotionAdwsReady

The timeout in minutes AutomatedLab waits for the Active Directory Web Services to respond.

### Timeout_DcPromotionRestartAfterDcpromo

The timeout in minutes to wait for a domain controller to finish restarting after DCPromo.

### Timeout_InstallLabCAInstallation

The timeout in minutes the installation of a Certificate Authority may take.

### Timeout_RestartLabMachine_Shutdown

The timeout in minutes to wait for the shutdown of a lab VM during ```Restart-LabVm```, which stops and then starts the VM.

### Timeout_Sql2008Installation

The timeout in minutes to wait for the SQL Server 2008 installation to finish.

### Timeout_Sql2012Installation

The timeout in minutes to wait for the SQL Server 2012 installation to finish.


### Timeout_Sql2014Installation

The timeout in minutes to wait for the SQL Server 2014 installation to finish.


### Timeout_StartLabMachine_Online

The timeout in minutes to wait for a lab VM to start.

### Timeout_StopLabMachine_Shutdown

The timeout in minutes to wait for a lab VM to stop.

### Timeout_VisualStudio2013Installation

The timeout for a Visual Studio 2013 installation.

### Timeout_VisualStudio2015Installation

The timeout for a Visual Studio 2015 installation.

### Timeout_WaitLabMachine_Online

The timeout in minutes for ```Wait-LabMachine```

### ValidationSettings

These settings relate to the lab validation.

- ValidRoleProperties: For each role, define the valid role properties to check for. Please do not change this setting unless you are debugging or developing AutomatedLab.
- For each role, define the mandatory role properties to check for. Please do not change this setting unless you are debugging or developing AutomatedLab.