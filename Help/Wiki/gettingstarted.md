## Placing ISO files
Of course AutomatedLab (AL) cannot install an operating system without actually having the bits. Hence you need to download an ISO file from MSDN, TechNet Evaluation Center or somewhere else. These files need to go to your folder "ISOs" located in the "LabSoures" folder.

The "ISOs" folder contains only one file after the installation of AL: "_Put all ISO images in here.txt". I have downloaded Windows Server 2016 from the TechNet Evaluation Center and put the file like shown below.

![ISOs](https://cloud.githubusercontent.com/assets/11280760/19439031/e13ab3a0-947c-11e6-9148-39f25078629a.png)

## Testing the ISO files
To make sure that AL can read the file, try to get a list of available operating systems. Open an **elevated** PowerShell ISE and call the following command (make sure you point to the right location for the LabSources folder:

``` powershell
Get-LabAvailableOperatingSystem -Path E:\LabSources
```

This returns a list of all operating system images found on the ISO file (of course this works also if there are a bunch of different OS ISOS in the folder).

![OSList](https://cloud.githubusercontent.com/assets/11280760/19439375/227bebee-947e-11e6-97fc-b402e91c91a3.png)

## Install the first lab
Plesae open an **elevated** PowerShell ISE and create a new empty document (CTRL+N) if not already open.

Copy and paste the following lines into the ISE:

***
``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2016 SERVERSTANDARD'

Install-Lab

Show-LabDeploymentSummary
```
***

The just press the run button or hit F5 to start the deployment.

This is what is going to happen. Many things happen automatically but can be customized:
* AutomatedLab starts a new lab named "GettingStarted". The lab defininition will be stored in C:\Users\%username%\Documents\AutomatedLab-Labs\GettingStarted. The location can be customized.
* AL will update download the SysInternals tools and put them into the LabSources folder.
* AL looks for an ISO file that contains the specified OS. If the ISO file cannot be found, the deployment stops.
* AL adds the one and only machine to the lab and recognizes that no network was defined. In this case, AL creates a virtual switch automatically and uses an free IP range.
* The AL measures the disk speed and chooses the fastet drive for the lab, as no location is defined in the call to "New-LabDefinition". In my case, it chooses D. Measuring is done only once and the result is cached.
* Then the actual deployment starts. AL creates
* 1.The virtual switch
* 2.Then it creates the a base image for the operating system that is shared among all machines with the same OS.
* 3.Afterwards the VM is created and started
* 4.AL waits for the machine to become ready and shows the overall installation time.

I have uploaded the [log of the deloyment](https://github.com/AutomatedLab/AutomatedLab/files/534026/GettingStarted.Log.docx). Your output should look pretty similar. In my case the deployment took about 10 minutes. It gets much faster if the base disk does already exist.

## Removing a Lab
If you want to get rid of the lab, just call Remove-Lab. The cmdlet removes the VMs including the disks and the virtual switches. It dies not touch the base disks.

If you have closed the ISE in the meantime, either specify the lab name or import it first.

![Remove1](https://cloud.githubusercontent.com/assets/11280760/19446945/93a01a26-949b-11e6-9aeb-1fb2933033dd.png)

## Summary
With AutomatedLab it is extremely easy to create various kinds of labs. The more you define your lab by code, the easier it is to re-deploy it and the less time you invest in the long term.

If you like what you have seen, take a look at the folder ["LabSources\Sample Scripts\Introduction"](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Introduction). These scripts demo how to create domains, internet facing labs, PKI, etc.

Please provide feedback if something does not work as expected. If you are missing a feature or have some great ideas, please open an [issue](https://github.com/AutomatedLab/AutomatedLab/issues).

# The AutomatedLab settings system

Since AutomatedLab version 5 we are using user-specific and global settings.

## Global settings

AutomatedLab uses a global settings file which is valid system-wide and is located in ```$env:ProgramFiles\WindowsPowerShell\Modules\AutomatedLab\<vx.y.z>\settings.PSD1```. Please do not remove any keys from this file, but feel free to alter them if necessary. Be aware that these settings will be overwritten when the module is updated however.

## User settings

A user settings file can be stored in ```$home\AutomatedLab\settings.PSD1``` allowing you to override settings defined in the global configuration. To do this, simply copy the parts of the PSD1 document you would like to override. This file is not touched during updates.

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