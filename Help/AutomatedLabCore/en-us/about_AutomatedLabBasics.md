# AutomatedLab Basics
## about_AutomatedLabBasics

# SHORT DESCRIPTION
Generic help about the basics of AutomatedLab

# LONG DESCRIPTION

## Getting started

### Placing ISO files
Of course AutomatedLab (AL) cannot install an operating system without actually having the bits. Hence you need to download an ISO file from MSDN, TechNet Evaluation Center or somewhere else. These files need to go to your folder "ISOs" located in the "LabSoures" folder.

The "ISOs" folder contains only one file after the installation of AL: "_Put all ISO images in here.txt". I have downloaded Windows Server 2016 from the TechNet Evaluation Center and put the file like shown below.

![ISOs](https://cloud.githubusercontent.com/assets/11280760/19439031/e13ab3a0-947c-11e6-9148-39f25078629a.png)

### Testing the ISO files
To make sure that AL can read the file, try to get a list of available operating systems. Open an **elevated** PowerShell ISE and call the following command (make sure you point to the right location for the LabSources folder:

``` powershell
Get-LabAvailableOperatingSystem -Path E:\LabSources
```

This returns a list of all operating system images found on the ISO file (of course this works also if there are a bunch of different OS ISOS in the folder).

![OSList](https://cloud.githubusercontent.com/assets/11280760/19439375/227bebee-947e-11e6-97fc-b402e91c91a3.png)

### Install the first lab
Please open an **elevated** PowerShell ISE and create a new empty document (CTRL+N) if not already open.

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
* AutomatedLab starts a new lab named "GettingStarted". The lab defininition will be stored in C:\ProgramData\AutomatedLab\Labs\GettingStarted. The location can be customized ["Advanced AutomatedLab Configurations"](../Advanced/automatedlabconfig.md) with the setting LabAppDataRoot.

  * AL will update download the SysInternals tools and put them into the LabSources folder.
  * AL looks for an ISO file that contains the specified OS. If the ISO file cannot be found, the deployment stops.
  * AL adds the one and only machine to the lab and recognizes that no network was defined. In this case, AL creates a virtual switch automatically and uses an free IP range.
  * The AL measures the disk speed and chooses the fastet drive for the lab, as no location is defined in the call to "New-LabDefinition". In my case, it chooses D. Measuring is done only once and the result is cached.
  * Then the actual deployment starts. AL creates

    1. The virtual switch
    2. Then it creates the a base image for the operating system that is shared among all machines with the same OS.
    3. Afterwards the VM is created and started
    4. AL waits for the machine to become ready and shows the overall installation time.

### Removing a Lab
If you want to get rid of the lab, just call Remove-Lab. The cmdlet removes the VMs including the disks and the virtual switches, and leaves the base disks for the next deployment.

If you have closed the ISE in the meantime, either specify the lab name or import it first.

![Remove1](https://cloud.githubusercontent.com/assets/11280760/19446945/93a01a26-949b-11e6-9aeb-1fb2933033dd.png)

### Summary
With AutomatedLab it is extremely easy to create various kinds of labs. The more you define your lab by code, the easier it is to re-deploy it and the less time you invest in the long term.

If you like what you have seen, take a look at the folder ["LabSources\Sample Scripts\Introduction"](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Introduction). These scripts demo how to create domains, internet facing labs, PKI, etc.

Please provide feedback if something does not work as expected. If you are missing a feature or have some great ideas, please open an [issue](https://github.com/AutomatedLab/AutomatedLab/issues).

### Next steps

Now that you have deployed your first lab, what comes next? Would you like to connect to the machines and run remote commands without you knowing the password? Then start with [the docs on lab management](./invokelabcommand.md).

Wondering how to transfer data to your new lab? Then start with [the docs on data exchange](./exchangedata.md).

If you - like us - like to tinker around with things, check out the [possible settings](../Advanced/automatedlabconfig.md).
Generally speaking AutomatedLab takes care of everything for you when deploying your labs on Azure. Since additional authentication is required it is possible that you need to login to your Azure account before using AutomatedLab.  
AutomatedLab works with Azure Resource Manager, so you can either execute the cmdlet `Connect-AzAccount` before deploying your lab or save your Azure Resource Manager profile.

### Azure

If you choose to login to your Azure account before a lab deployment, your profile is being saved for you to be able to import the lab at a later stage. Since it is possible that your profile expires you might see an error message indicating your profile expiration. In that case, simply login to your Azure account again.

```powershell
New-LabDefinition -Name 'MyLab' -DefaultVirtualizationEngine Azure

## Optional to set e.g. your preferred location
Add-LabAzureSubscription -DefaultLocation 'West Europe'
```

> **Warning**
> Please use VM sizes with a decent number of IOPS! If you opt not to do this,
> you will notice your deployments running into errors, timeouts and the like.

This will enable AutomatedLab to create a lab sources resource group for you as well as a separate resource group for each lab you deploy. Your lab resource group will contain the entire lab deployment and will be removed when you call `Remove-Lab`.

### Azure Stack Hub

To be able to target Azure Stack Hub with its special set of APIs, there is a bit more to do before deploying labs.

To successfully use Azure Stack Hub, there are a few prerequisites:
- A properly configured and registered Azure Stack Hub to connect to!
  - Deploy an SDK here: https://github.com/Azure-Samples/Azure-Stack-Hub-Foundation-Core/tree/master/Tools/ASDKscripts
- Connectivity to the Hub that is being used, for example via VPN
  - Using an SDK and Bastion is too expensive? Try a VPN: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-rm-ps
- A subscription on Azure Stack Hub!
  - Make sure all relevant resource providers (Compute, Network, Storage, ...) are registered in your subscription - this does *not* happen automatically.
  - Make sure that your lab does not exceed the quota set by your AzS Hub Operator
- Verify (or ask your AzS Operator) that the marketplace is populated with Operating System images compatible with AutomatedLab (i.e. Windows Server, SQL Server)
- Internet connectivity of your host system in order to download the required modules
  - Validate versions yourself: `Test-LabAzureModuleAvailability -Verbose -AzureStack`
  - Required versions: `Get-LabConfigurationItem -Name RequiredAzStackModules`

First of all, ensure that the prehistoric module versions required for Azure Stack Hub are installed:

```powershell
Remove-Module -Name Az.* -Force

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    Install-LabAzureRequiredModule -AzureStack
}

if (-not (Test-LabAzureModuleAvailability -AzureStack))
{
    throw "One or more required modules are missing. Please use 'Install-LabAzureRequiredModule -AzureStack' first"
}
```

In addition to very specific PowerShell module versions, the connection to Azure Stack requires you to connect to your
environment.
```powershell
$Environment = 'azs'
$ArmEndpointUrl = 'https://management.local.azurestack.external' # Use your own!
$AzureAd = $true # If using ADFS -> $false
$AADTenantName = 'YourTenantName.onmicrosoft.com' # Use your own!

if (-not (Get-AzEnvironment -Name $Environment))
{
    $null = Add-AzEnvironment -Name $Environment -ArmEndpoint $ArmEndpointUrl
}

if (-not (Get-AzContext) -or (Get-AzContext).Environment.Name -ne $Environment)
{
    if ($AzureAd)
    {
        $AuthEndpoint = (Get-AzEnvironment -Name $Environment).ActiveDirectoryAuthority
        $TenantId = (Invoke-RestMethod "$($AuthEndpoint)$($AADTenantName)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]
        $null = Connect-AzAccount -EnvironmentName $Environment -TenantId $TenantId
    }
    else
    {
        $null = Connect-AzAccount -EnvironmentName $Environment
    }
}
```

Lastly, in your lab script, make sure that you use the correct location and environment, as well as the `AzureStack` parameter.



```powershell
New-LabDefinition -Name AzSLab -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName local -Environment $Environment -AzureStack
```
Adding machines to a lab ranges from extremely easy to fairly complicated. Both is achieved with one cmdlet though, Add-LabMachineDefinition.

```powershell
## Add the root domain controller for the domain contoso.com
## Network, memory, ... will all be handled automatically
Add-LabMachineDefinition -Name DC1 -Roles RootDC -OperatingSystem 'Windows Server 2019 Datacenter' -Domain contoso.com
```

When you are using the automatic machine definitions, the memory requirements will be calculated based on the machines' roles.

If the normal operating system and version combinations are not sufficient on Hyper-V, you can also find your OS
and pass the entire object instead of the OS name. This takes care of oddities such as 32bit Windows versions
that unfortunately have the same name as their normal 64bit kin.

```powershell
$x86os = (Get-LabAvailableOperatingSystem -UseOnlyCache | Where {$_.OperatingSystemName -eq 'Windows 10 Enterprise LTSC' -and $_.Architecture -eq 'x86'})
$x64os = (Get-LabAvailableOperatingSystem -UseOnlyCache | Where {$_.OperatingSystemName -eq 'Windows 10 Enterprise LTSC' -and $_.Architecture -eq 'x64'})
Add-LabMachineDefinition -Name test64 -OperatingSystem $x64os
Add-LabMachineDefinition -Name test32 -OperatingSystem $x86os

Install-Lab
```

### Deploying a lab with Linux VMs
With AutomatedLab Linux VMs can be deployed just as easily as Windows VMs. The current implementation should take care of the following distributions:
- RHEL 7+ (*)
- CentOS 7+
- Ubuntu 14.04+, Kali (Not on Hyper-V, nyanhp was not able to get cloudinit to work properly)
- Fedora 27+ (not on Azure, there are only paid plans)
- SLES 12.3+ (*) (not on Azure, there are only paid plans)
- OpenSuSE (not on Azure, there are only paid plans)

At the moment the machines do not support any of AutomatedLab's roles since our roles are Windows-based. However, your VMs should come up domain-joined and capable of receiving WSMAN or SSH requests. AutomatedLab uses kickstart (RHEL-based) or AutoYAST (SLES-based) to configure everything that would be configured in the unattend file of a Windows machine.

>NOTE: Please do not expect PowerShell to run on something unsupported (<https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle?view=powershell-7.5#supported-platforms>). We **need** PowerShell to remote into the lab VMs and run our customizations. You can still add random Linux hosts, but please do not
raise issues for this. Troubleshooting on those OSses is very time- and money-consuming.

WSMAN (or rather omi-psrp-server) support is very spotty. To address this issue, please use the parameters `SshPublicKeyPath` and
`SshPrivateKeyPath` when deploying Linux hosts. No idea how SSH keys are generated? Look here: <https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed>

### Simple Linux lab
You can find the Linux lab here: [AL Loves Linux](https://github.com/AutomatedLab/AutomatedLab/blob/develop/LabSources/SampleScripts/HyperV/AL%20Loves%20Linux.ps1)
As you can see, integrating Linux clients is very simple in general:  
```powershell
Add-LabMachineDefinition -Name LINCN2 -OperatingSystem 'CentOS 7.4'
```  
If you want to add additional package groups to be installed during setup, you can do so by specifying them:  
```powershell
Add-LabMachineDefinition -RhelPackage domain-client -Name LINCN1 -OperatingSystem 'CentOS 7.4' -DomainName contoso.com
```  
You can find all available packages with ```Get-LabAvailableOperatingSystem | Select-Object -Expand LinuxPackageGroup```. However, the basics should be fine for most cases.  
At them moment, your Linux-based labs need an internet connection (i.e. a routing VM) so that the PowerShell and omi-psrp-server can be downloaded during setup. Without omid running on the Linux machines, your lab will run into a timeout during installation. While this will not break things, it will certainly cause a long wait.

### Azure-specific properties

There are several properties that can be used with the `AzureProperties` parameter of the `Add-LabMachineDefinition` cmdlet.

- ResourceGroupName - Resource group this machine is deployed into, if it should be different
- UseAllRoleSizes - Use a random role size of the available role sizes
- RoleSize - Use specific role size like Standard_D2_v2
- LoadBalancerRdpPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerWinRmHttpPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerWinRmHttpsPort - Use a different port for the inbound NAT rule. Needs to be unique in your lab!
- LoadBalancerAllowedIp - A comma-separated string (NOT an array) containing IP addresses allowed to connect, e.g. "$(Get-PublicIpAddress), 1.2.3.4"
- SubnetName - The subnet name this machine is deployed into
- UseByolImage - Boolean as string indicating that BYOL licensing is used
- AutoshutdownTime - The timespan as string when the machines shut be shut down
- AutoshutdownTimezoneId - The time zone ID as string for the auto shutdown time
- StorageSku - The storage SKU for additional disks. OS disks are managed disks. Either 'Standard_LRS', 'Premium_LRS' or 'StandardSSD_LRS'
Creating your lab starts with New-LabDefinition. This cmdlet creates a container that holds all the lab items like networks and machines.

It is mandatory to define the name of the lab and the virtualization engine. So far AL supports Hyper-V and Azure.

``` powershell
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -VmPath D:\AutomatedLab-VMs
```

- **New-LabDefinition** Parameters
  - **Name**: The name of the lab to create. The name must be unique.
  - **DefaultVirtualizationEngine**: HyperV for local deployments or Azure to deploy into the cloud.
  - **VmPath**: This is where AL creates the virtual machines. If this path is not defined AL will choose the fastest drive by trying not to use the system drive and create a folder there names "AutomatedLab-VMs".

During the lab deployment, AL exports your definitions into XML files. By default these are stored in 'C:\Users\<username>\Documents\AutomatedLab-Labs'. If you close the PowerShell session after the lab deployment, you can import the lab again using the Import-Lab cmdlet.

![Lab Definition Files](https://cloud.githubusercontent.com/assets/11280760/20555110/6f12f9a8-b160-11e6-863a-bac119eac71b.png)

The virtual machines are stored in a different folder. AL tries to determine the fastest drive and uses the cmdlet Get-DiskSpeed for this. AL tries to avoid using the system drive. The speed test runs only once and results are cached. However if you plug in a new drive, AL takes it into consideration and measure its speed.

![VM Folder](https://cloud.githubusercontent.com/assets/11280760/20642671/252e839a-b415-11e6-8c80-307f7662d64a.JPG)

Starting with version 5.23, each lab deployment will not only be validated before the deployment but also
when the installation is finished. To enable the deployment validation, you need to install Pester 5.0.1+.
We did not mark Pester as a dependency, as these tests are optional.

### Lab building with the REST API

With the custom role 'LabBuilder' it is now possible to create a simple REST API powered by [Polaris](https://github.com/PowerShell/Polaris) on any virtualization host. The REST API provides the following functionality:

#### Create

```powershell
$request = @{
    LabScript = Get-Content "$labsources\Sample Scripts\Introduction\01 Single Win10 Client.ps1" -Raw
} | ConvertTo-Json

## Queue new job, use GUID to request status update with GET method
$guid = Invoke-RestMethod -Method Post -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

#### Read

```powershell
## All labs (Get-Lab -List)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Labs
## Specific lab
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10
## Lab creation job (monitoring long running jobs)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Id=5b89babb-7402-4a7a-9c16-86e1d52613fa
```

#### Delete

```powershell
## As query parameter
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab?Name=Win10

## Or as JSON body
$request = @{Name = 'Win10'} | ConvertTo-Json
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

#### Lab scenario including the builder

The following lab scenario configures a simple VM to test-drive this feature. Be aware that when using this on Azure your lab sources need to be uploaded first. Otherwise you will need to manually copy all necessary ISO files to your Azure VM.

```powershell
<#
Build a lab with the help of nested virtualization. Adjust the machine memory if necessary.
The build worker will use Polaris as a simple REST endpoint that takes your lab data to deploy.

AutomatedLab will be copied to the machine. Lab sources will be mirrored to the machine as well, so that lab deployments can start immediately
##>
param
(
    [string]
    $LabName = 'LabAsAService',

    [ValidateSet('yes','no')]
    $TelemetryOptOut = 'no' # Opt out of telemetry for build worker by saying yes here
)

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
Add-LabVirtualNetworkDefinition -Name $labName -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$role = Get-LabPostInstallationActivity -CustomRole LabBuilder -Properties @{TelemetryOptOut = $TelemetryOptOut}

$machineParameters = @{
    Name                     = 'NestedBuilder'
    PostInstallationActivity = $role
    OperatingSystem          = 'Windows Server 2016 Datacenter (Desktop Experience)'
    Memory                   = 16GB
    Network                  = $labName
    DiskName                 = 'vmDisk'
}

$estimatedSize = [Math]::Round(((Get-ChildItem $labsources -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB + 20), 0)
$disk = Add-LabDiskDefinition -Name vmDisk -DiskSizeInGb $estimatedSize -PassThru

Add-LabMachineDefinition @machineParameters

Install-Lab
```
### Summary
One basic requirement is sending files to a lab machine as well as receiving files. Both is supported by AutomatedLab, for files and also directory trees.
This feature works with Hyper-V VMs as well as Azure VMs.

### How to use it – send
To send a file or directory to a lab machine, only the local source path and the machine name is required. There is no difference whether the machine is on Hyper-V or Azure.
```
Note: Copy-LabFileItem wraps the cmdlets Send-File and Send-Directory,
both define in the PSFileTransfer module.
```

If the target path is not defined, the file or folder will be put in C:\. The parameter ComputerName is an array and data can be copied to a single or multiple machines with a single command.

The following command copies a file to the specified machine trying SMB first and falling back to WinRM.

``` PowerShell
Copy-LabFileItem -Path 'D:\170630 AL' -ComputerName wServer1 -DestinationFolderPath C:\Temp
```

The following samples are using the PSFileTransfer cmdlets directly. These do not support SMB and send the files over the PSSession right away. The Force switch creates the target folder if not already existing.
```
Note: It is recommended to use Copy-LabFileItem as SMB is much faster
then sending a byte array over WinRM.
```

``` PowerShell
$s = New-LabPSSession LabVM1
Send-File -SourceFilePath D:\Untitled1.ps1 -DestinationFolderPath C:\Temp\Untitled1.ps1 -Session $s -Force
Send-Directory -SourceFolderPath D:\Test -DestinationFolderPath C:\Windows -Session $s
```

### How to use it – receive
This also works the other way around. If some process creates files on a lab machine that are required for another process on another lab machine, you can retrieve and re-send the file to another machine.

For example, this process is used in the AutomatedLab’s certificate functions like Get-LabCAInstallCertificates.

``` PowerShell
Receive-File -SourceFilePath C:\Unattend.xml -DestinationFilePath D:\Unattend.xml -Session $s
Receive-Directory -SourceFolderPath 'C:\Program Files\Wireshark' -DestinationFolderPath D:\Wireshark -Session $s
```
### Internals
Hyper-V machines are usually reachable from the host by SMB. However, it is not sure or pretty unlikely if the other way works as well, accessing the host machines from the VM.

Copy-LabFileItem always tries SMB first. If this does not work, it uses the PowerShell session and transfers the file as a Byte[]. Reading and writing a file as a byte array, serializing the byte array and sending it over the network is much slower than SMB but totally sufficient for most scenarios. If you transfer large files, make sure SMB works from the host to the VMs.

```
Note: All the functions of the module PSFileTransfer do not rely on other modules
of AutomatedLab and can be used separately.
```
## Offline lab scenario

To deploy complex lab scenarios offline you will at some point run into issues due to additional dependencies being downloaded. This article aims to give you all the necessary information to prepare for a fully offline environment.

### Basics

First of all, install AutomatedLab from the MSI installer and get some ISO files - like you would for an online scenario. Place your ISO files in LabSources\ISOs. The MSI installer contains all static files that we need like ProductKeys.xml, WinSAT and so on.

### DSC Pull Server

To deploy the pull server role, we download the Access Database Engine from `Get-LabConfigurationItem -Name AccessDatabaseEngine2016x86` to LabSources/SoftwarePackages without renaming the file.

### Office

To deploy Office Server, the Office deployment toolkit is needed at LabSources/SoftwarePackages/OfficeDeploymentTool.exe. You can download the tool from `Get-LabConfigurationItem -Name OfficeDeploymentTool`.

### SharePoint

SharePoint requires a whole slew of prerequisites. First of all, you should download all CPP redistributables from 2012 up to 2017, 32 and 64 bit, following the naming pattern vcredist_BITS_YEAR e.g. vcredist_64_2012. The links can be easily accessed using `Get-LabConfigurationItem -Name cppredist*`. The more descriptive version is `Get-PSFConfig -Module AutomatedLab -Name cppredist*` which shows you the version as well. All packages need to be downloaded to LabSources/SoftwarePackages

The rest of the requirements is version-dependent. The links are best accessed using `Get-LabConfigurationItem -Name SharePoint2019Prerequisites`. Please make sure that for SharePoint 2013 the download with an URI containing 1CAA41C7 needs to be renamed to WcfDataServices56.exe.

### SQL

SQL also requires a bunch of prerequisites. First of all, you should download all CPP redistributables from 2015 up to 2017, 32 and 64 bit, following the naming pattern vcredist_xARCHITECTURE_YEAR e.g. vcredist_x86_2015.exe. The links can be easily accessed using `Get-LabConfigurationItem -Name cppredist*`. The more descriptive version is `Get-PSFConfig -Module AutomatedLab -Name cppredist*` which shows you the version as well. All packages need to be downloaded to LabSources/SoftwarePackages.

Additionally, .NET 4.8 will be required on SQL 2017 and newer when reporting services are deployed, which can be downloaded from `Get-LabConfigurationItem -Name dotnet48DownloadLink`. The download should be stored in LabSources/SoftwarePackages.

While not strictly required, you might want to download the following packages as well, thereby reducing some error messages:
- SQL Server Reporting Services: `Get-LabConfigurationItem -Name Sql$($server.SqlVersion)SSRS` to `LabSources/SoftwarePackages/Sql$($server.SqlVersion)\SQLServerReportingServices.exe`
- SQL Server Report Builder: `Get-LabConfigurationItem -Name SqlServerReportBuilder` to `LabSources\SoftwarePackages\ReportBuilder.msi`
- SQL Server Management Studio: `Get-LabConfigurationItem -Name Sql$($server.SqlVersion)ManagementStudio` to `LabSources/SoftwarePackages/Sql$($server.SqlVersion)/SSMS-Setup-ENU.exe`
- Sample Databases: Download the desired sample databases as .bak files to LabSources\SoftwarePackages\SqlSampleDbs\SqlServerXXXX. The files should be called as the directory, SqlServerXXXX.bak, where XXXX is the version of SQL.

### Team Foundation Server and Azure DevOps

A recent TFS/Azure DevOps agent is required which can be downloaded from `Get-LabConfigurationItem -Name BuildAgentUri` and needs to be stored as `LabSources\Tools\TfsBuildWorker.zip`.
## Getting started

### Placing ISO files
Of course AutomatedLab (AL) cannot install an operating system without actually having the bits. Hence you need to download an ISO file from MSDN, TechNet Evaluation Center or somewhere else. These files need to go to your folder "ISOs" located in the "LabSoures" folder.

The "ISOs" folder contains only one file after the installation of AL: "_Put all ISO images in here.txt". I have downloaded Windows Server 2016 from the TechNet Evaluation Center and put the file like shown below.

![ISOs](https://cloud.githubusercontent.com/assets/11280760/19439031/e13ab3a0-947c-11e6-9148-39f25078629a.png)

### Testing the ISO files
To make sure that AL can read the file, try to get a list of available operating systems. Open an **elevated** PowerShell ISE and call the following command (make sure you point to the right location for the LabSources folder:

``` powershell
Get-LabAvailableOperatingSystem -Path E:\LabSources
```

This returns a list of all operating system images found on the ISO file (of course this works also if there are a bunch of different OS ISOS in the folder).

![OSList](https://cloud.githubusercontent.com/assets/11280760/19439375/227bebee-947e-11e6-97fc-b402e91c91a3.png)

### Install the first lab
Please open an **elevated** PowerShell ISE and create a new empty document (CTRL+N) if not already open.

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
* AutomatedLab starts a new lab named "GettingStarted". The lab defininition will be stored in C:\ProgramData\AutomatedLab\Labs\GettingStarted. The location can be customized ["Advanced AutomatedLab Configurations"](../Advanced/automatedlabconfig.md) with the setting LabAppDataRoot.

  * AL will update download the SysInternals tools and put them into the LabSources folder.
  * AL looks for an ISO file that contains the specified OS. If the ISO file cannot be found, the deployment stops.
  * AL adds the one and only machine to the lab and recognizes that no network was defined. In this case, AL creates a virtual switch automatically and uses an free IP range.
  * The AL measures the disk speed and chooses the fastet drive for the lab, as no location is defined in the call to "New-LabDefinition". In my case, it chooses D. Measuring is done only once and the result is cached.
  * Then the actual deployment starts. AL creates

    1. The virtual switch
    2. Then it creates the a base image for the operating system that is shared among all machines with the same OS.
    3. Afterwards the VM is created and started
    4. AL waits for the machine to become ready and shows the overall installation time.

### Removing a Lab
If you want to get rid of the lab, just call Remove-Lab. The cmdlet removes the VMs including the disks and the virtual switches, and leaves the base disks for the next deployment.

If you have closed the ISE in the meantime, either specify the lab name or import it first.

![Remove1](https://cloud.githubusercontent.com/assets/11280760/19446945/93a01a26-949b-11e6-9aeb-1fb2933033dd.png)

### Summary
With AutomatedLab it is extremely easy to create various kinds of labs. The more you define your lab by code, the easier it is to re-deploy it and the less time you invest in the long term.

If you like what you have seen, take a look at the folder ["LabSources\Sample Scripts\Introduction"](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Introduction). These scripts demo how to create domains, internet facing labs, PKI, etc.

Please provide feedback if something does not work as expected. If you are missing a feature or have some great ideas, please open an [issue](https://github.com/AutomatedLab/AutomatedLab/issues).

### Next steps

Now that you have deployed your first lab, what comes next? Would you like to connect to the machines and run remote commands without you knowing the password? Then start with [the docs on lab management](./invokelabcommand.md).

Wondering how to transfer data to your new lab? Then start with [the docs on data exchange](./exchangedata.md).

If you - like us - like to tinker around with things, check out the [possible settings](../Advanced/automatedlabconfig.md).
## Getting started on Linux

As the creators of AutomatedLab did not have Linux in mind from the beginning, Linux as the host system is still slightly behind on capabilites.
Nevertheless, you very much can use Linux to deploy labs, provided you have access to an Azure subscription and are allowed to
create resource groups. One will contain a storage account that is reused and contains your otherwise local lab sources.

If you are not allowed to create resource groups, you need to have one resource group per lab that is being deployed with you being the resource
group's contributor. The name of the resource group is to be the name of the lab.

### Install and configure AutomatedLab

Installation on Linux is recommended using the PowerShell Gallery.

```powershell
Install-Module AutomatedLab
```

If you did not run PowerShell as root (`su pwsh`), please customize and run the following command to set up the required folder structure:
```powershell
mkdir $home/automatedlab
Set-PSFConfig -FullName AutomatedLab.LabAppDataRoot -Value $home/automatedlab -PassThru | Register-PSFConfig
```

At the time of writing, only Azure-based labs are available on Linux. In order to use AutomatedLab, the following commands should be run after installing AutomatedLab.

```powershell
Install-LabAzureRequiredModule
Connect-AzAccount -UseDeviceAuthentication
```

Optionally, you can scaffold the lab sources directory containing sample scripts and other content. Some roles as well as custom roles require
content from this directory anyways.

```powershell
mkdir $home/labsources
Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value $home/labsources -PassThru | Register-PSFConfig
New-LabSourcesFolder -Force
```


### Install the first lab

To install a very basic lab with one VM, run the following commands in PowerShell

***
``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine Azure

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2019 Datacenter'

Install-Lab

Show-LabDeploymentSummary
```
***

> **Warning**
> AutomatedLab can only work if remoting is configured properly. This seems to be highly difficult on Linux.
> Should you have issues with remoting, please first of all try to `Install-Module PSWSMAN; Install-WSMAN`
> If this does not work for you, you can specify public and private key to connect. This will however
> not work in all scenarios: A double hop is required for many roles like SQL, Azure DevOps or Certificate Authorities.

### Install lab using SSH remoting

To install the same basic lab with SSH remoting, run the following commands in PowerShell, using your own
private and public keys.

``` powershell
New-LabDefinition -Name GettingStarted -DefaultVirtualizationEngine Azure

Add-LabMachineDefinition -Name FirstServer -OperatingSystem 'Windows Server 2019 Datacenter' -SshPublicKeyPath $home/.ssh/MyPubKey.pub -SshPrivateKeyPath $home/.ssh/MyPrivKey

Install-Lab

Show-LabDeploymentSummary
```

All connections will use your key pair instead of a password. That however means that no second hop will be possible. The combination
of `-K` and `-i` does not work together, as stated here: <https://www.man7.org/linux/man-pages/man1/ssh.1.html#AUTHENTICATION>

### Next steps

Now that you have deployed your first lab, what comes next? Would you like to connect to the machines and run remote commands without you knowing the password? Then start with [the docs on lab management](./invokelabcommand.md).

Wondering how to transfer data to your new lab? Then start with [the docs on data exchange](./exchangedata.md).

If you - like us - like to tinker around with things, check out the [possible settings](../Advanced/automatedlabconfig.md).
## Installation

There are two options installing AutomatedLab:

- You can use the [MSI installer](https://github.com/AutomatedLab/AutomatedLab/releases) published on GitHub.
- Or you install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AutomatedLab/) using the cmdlet Install-Module.  
    **Please note that this is the ONLY way to install AutomatedLab and its dependencies in PowerShell Core/PowerShell 7 on both Windows and Linux/Azure Cloud Shell**

### From gallery
```powershell
Install-PackageProvider Nuget -Force
## SkipPublisherCheck: AutomatedLabTest requires Pester v5. On system where Pester v3 is still the only versions, you will get an error if the parameter is not present
Install-Module AutomatedLab -SkipPublisherCheck

##region Non-interactive host
## Pre-configure telemetry
if ($IsLinux -or $IsMacOs)
{
    # Disable (which is already the default) and in addition skip dialog
    $null = New-Item -ItemType File -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.disabled" -Force

    # Enable
    $null = New-Item -ItemType File -Path "$((Get-PSFConfigValue -FullName AutomatedLab.LabAppDataRoot))/telemetry.enabled" -Force
}
else
{
    #  Disable (which is already the default) and in addition skip dialog
    [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'false', 'Machine')
    $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'false'

    # Enable
    [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'true', 'Machine')
    $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'true'
}

## Pre-configure Lab Host Remoting
Enable-LabHostRemoting -Force

## Using Azure: Pre-configure Lab Sources Synchronization
## Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name LabSourcesMaxFileSizeMb
## Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name LabSourcesSyncIntervalDays
## Get/Set/Register/Unregister-PSFConfig -Module AutomatedLab -Name AutoSyncLabSources
##endregion

## If you are on Linux and are not starting pwsh with sudo
## This needs to executed only once per user - adjust according to your needs!
Set-PSFConfig -Module AutomatedLab -Name LabAppDataRoot -Value /home/youruser/.alConfig -PassThru | Register-PSFConfig

## Prepare sample content - modify to your needs

## Windows
New-LabSourcesFolder -DriveLetter C

## Linux
Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Value /home/youruser/labsources -PassThru | Register-PSFConfig
New-LabSourcesFolder # Linux
```

### From MSI
AutomatedLab (AL) is a bunch of PowerShell modules. To make the installation process easier, it is provided as an MSI.

Download Link: https://github.com/AutomatedLab/AutomatedLab/releases

There are not many choices when installing AL.

![Install1](https://cloud.githubusercontent.com/assets/11280760/19437688/c01dce38-9476-11e6-8981-d3175d0251e2.png)

The options Typical and Complete are actually doing the same and install AL to the default locations. The PowerShell modules go to "C:\Program Files\WindowsPowerShell\Modules", the rest to "C:\LabSources".

As LabSources can grow quite big, you should go for a custom installation and put this component on a disk with enough free space to store the ISO files. This disk does not have to be an SSD. Do not change the location of the modules unless you really know what you are doing.

![Install2](https://cloud.githubusercontent.com/assets/11280760/19437729/eef3e706-9476-11e6-9b16-982bd069f88d.png)

Very important to AL is the LabSources folder that should look like this:

![Install3](https://cloud.githubusercontent.com/assets/11280760/19438445/5256c3ba-947a-11e6-85b1-68ecc667e59b.png)

If all that worked you are ready to go for [Getting Started](https://github.com/AutomatedLab/AutomatedLab/wiki/2.-Getting-Started).

### Summary
Installing software on lab machines is almost as easy as installing Windows Features.  And there are similar challenges. But additional to the challenges, some installers have an extra demand, like the .NET 4.5.2 package that cannot be installed remotely. Like when installing Windows Features, AutomatedLab tries to provide a solution that makes this task as simple as possible. It does not matter if the **installation file is already on the VM or on your host machine**. And you do not have to care whether it is a **.exe, .msi or .msu** file, AL will handle the complexity for you. And there is also a very convenient way to **install stuff from ISOs** mounted to the lab VMs.

#### Install-LabSoftwarePackage Introduction
The cmdlet that handles the installation is Install-LabSoftwarePackage. It is designed to work in various scenarios that will be discussed in this article.
Internally, it uses Invoke-LabCommand again to connect to the lab VMs by using the credentials known to the lab. The files are copied to the lab VMs using Copy-LabFileItem.

#### Install-LabSoftwarePackage Usage
##### Installing a package that is on the host machine
A very simple demonstration of how the cmdlet can help, is installing Notepad++ on a lab VM. Note that $labSources always points to the LabSources folder that is created by AL, so you do not have to provide the full path. This also works on Azure. A lab VM hosted on Azure accesses the share hosted on Azure by default. The Azure LabSources share can be synced with the local one.
The next command copies the Notepad++.exe file to the VM and invokes the installer. The package must support a silent installation. For Notepad++, you can switch to the silent mode by providing the argument “/S” (case-sensitive).
``` PowerShell
Install-LabSoftwarePackage -ComputerName Server1 -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
```
If you want to install the same package to all machines in a lab, regardless if they run on Hyper-V or Azure, just change the ComputerName parameter:
``` PowerShell
Install-LabSoftwarePackage -ComputerName (Get-LabVM) -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
```
##### Installing a package that is on the host machine as scheduled job
Some software packages are creating headaches, like the .NET Framework 4.5.2. The package calls the Windows Update Service which checks if it is called remotely by checking the token for the NETWORK RID, and cancels the installation if that’s the case.
Install-LabSoftwarePackage offers the switch AsScheduledJob to be able to start the installation remotely which then actually runs locally.
The next example shows how to install .net 4.5.2 on a VM, restart the VM and then install the Windows Management Framework 5.1.

``` PowerShell
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\NDP452-KB2901907-x86-x64-AllOS-ENU.exe -CommandLine '/q /norestart /log c:\dotnet452.txt' -ComputerName Client7 -AsScheduledJob -UseShellExecute
Restart-LabVM -ComputerName Client7 -Wait

Install-LabSoftwarePackage -Path $labSources\V5\Win7AndW2K8R2-KB3134760-x64.msu -ComputerName Client7
Restart-LabVM -ComputerName Client7 -Wait
```

##### Installing a package that is already on the VM
Installing software packages that are already on the VM is also possible. In this case, you can use the LocalPath parameter instead of the Path parameter.

The following command installs the Redgate Reflector on all machines with the role visual studio, expecting the package already to be at C:\. The AsJob switch puts the work into the background.
``` PowerShell
Install-LabSoftwarePackage -LocalPath C:\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName (Get-LabMachine -Role VisualStudio2015) -AsJob
```
##### Installing Files from ISO Files mounted to lab VMs.
The cmdlet Install-LabSoftwarePackage is even more effective when combined with other cmdlets AutomatedLab provides. When mounting an ISO into a VM, it is not guaranteed that the ISO will get always the same drive letter. If a lab VM has only one drive, the ISO will be pretty likely drive D:, but if the lab VM has more than one disk attached, things are getting more complex.
Mount-LabIsoImage returns the drive an ISO file actually has inside the VM. This information can be used to construct the path to call. This is demoed in the next example.
``` PowerShell
$drive = Mount-LabIsoImage -ComputerName Web1 -IsoPath $labSources\ISOs\SkypeForBusiness2015.iso -PassThru
Install-LabSoftwarePackage -ComputerName Web1 -LocalPath "$($drive.DriveLetter)\Setup.exe" -CommandLine /BootStrap
Dismount-LabIsoImage -ComputerName Web1
```

For further help and details on the available parameters please call Get-Help Install-LabSoftwarePackage.
### Summary
A quite common task in a lab is to add Windows features to one or some machines. This can be easily done using the cmdlet Install-WindowsFeature that is available since Windows Server 2008 R2. It is also quite easy to the cmdlet on another machine by using Install-WindowsFeature inside a scriptblock that you invoke on a remote machine using Invoke-Command. However, this requires authentication, creating the scriptblock and other things. The cmdlet Install-LabWindowsFeature does this all for you.

#### Installing Windows Features using Install-LabWindowsFeature
Install-LabWindowsFeature uses Invoke-LabCommand that is discussed in <TODO>. As Invoke-LabCommand handles obstacles like name resolution and authentication with the standard lab account, which makes this task even easier.
The following command installs the Remote Sever Administration tools (RSAT) on the machines Server1 and Server2:

``` PowerShell
Install-LabWindowsFeature -FeatureName RSAT -ComputerName 'server1', 'server2' -IncludeAllSubFeature 
```
It is also possible to push the activity into the background using the AsJob switch. You can start the installation on multiple machines and then wait for the jobs to complete. 

If AsJob is used along with PassThru, Install-LabWindowsFeature returns the job objects. If just PassThru is used, the cmdlet return the result of the feature installation.

``` PowerShell
$jobs = Install-LabWindowsFeature -FeatureName RSAT -ComputerName 'server1', 'server2' -IncludeAllSubFeature -AsJob -PassThru
$result = Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay -PassThru
```
PowerShell offers a great way to run code on remote machines by means of the cmdlet Invoke-Command. This cmdlet just needs to get a script block to run and computer names. However, connecting to a lab machine that is not in the same security context requires authentication. Also, double-hop authentication scenarios (CredSsp) need some configuration to work.
Another challenge is making local variables and local functions available to remote PowerShell sessions. In this regards AL as a framework gives you some nice tools that are making PowerShell Remoting even more effective.
Lab environments usually do not share the same namespace or DNS servers. Hence AL comes up with its own name resolution system. It lets you connect to the machines with the short names regardless whether they are hosted on Hyper-V or Azure.  

### Invoke-LabCommand
Invoke-LabCommand is like a proxy. It works pretty similar to Invoke-Command but adds a lot of functionality that makes working in a lab even easier. The next sections are describing each of these additional features with some samples.
#### Name Resolution
AL needs to support two different ways of name resolution as it supports labs on the loal Hyper-V and on Windows Azure.
For Hyper-V scenarios AL creates an entry in the LMHosts file. Connecting to Hyper-V VMs created by AL works with the standard naming resolution.
A bit more work is done behind the scenes for VMs hosted on Azure. AL reads the public IP address of the load balancer each machine is connected to and also discovers the public port for WinRM. This information is added to each machine (see AzureConnectionInfo property) and used inside Invoke-LabCommand. Actually the hard work is done inside the cmdlet New-LabPSSession which also caches connections. The cmdlets Enter-LabPSSession and Connect-LabVM are implementing the AL name resolution as well.
Running a command on a specific VM, regardless if it is hosted on Azure or Hyper-V, works like this (Without the PassThru switch, Invoke-LabCommand does not return any data):
``` PowerShell
Invoke-LabCommand -ScriptBlock { Get-Date } -ComputerName Client1 -PassThru
```

Running a command on all lab VMs, regardless if they are hosted on Azure or Hyper-V, works like this:
``` PowerShell
Invoke-LabCommand -ScriptBlock { Get-Date } -ComputerName (Get-LabVM)
```
#### Making local variables and functions available remotely
If you have functions and variables defined locally, they are not available in the remote session. With the using scope (PowerShell 3+) you can access local variables in the remote session but it requires changing the code by adding “$using:” to each variable you want to retrieve from the local scope. Hence this code will no longer work locally which makes debugging your code locally on the VM much harder.
Invoke-LabCommand provides the two parameters “Variable” and “Function”. All the variables and functions given here are pushed to the remote session making them available there.
The following sample demonstrates this by having a local function that just returns the value of a local variable. Invoke-LabCommand runs the same code on a remote machine without changing anything.
The code you may run locally:
``` PowerShell
function Foo
{
    "The calue of '`$someVar' is $someVar"
}

$someVar = 123
Foo
```

To run the same code remotely
``` PowerShell
function Foo
{
    "The calue of '`$someVar' is $someVar"
}

$someVar = 123

Invoke-LabCommand -ComputerName Client1 -ScriptBlock { Foo } -Variable (Get-Variable -Name someVar) -Function (Get-Command -Name Foo)
```
#### Double-Hop Authentication and CredSsp
Every machine deployed with AL has CredSsp enabled as a CredSsp server. This is like running “Enable-WSManCredSSP -Role Server”. Invoke-LabCommand always tries to make a connection with CredSsp. If this does not work you will see a warning and a connection without CredSsp is tried. This is definitely not a best practice for a production environment but makes life much easier in a lab. Using CredSsp you can create a remote session from a remote session which is extremely helpful when installing or setting up a lab.
For example, reading an AD user account from a remote session does not work without CredSsp as reading data from Active Directory requires and authentication from the remote machine to a domain controller. Inside an AL lab the following code works out of the box.
``` PowerShell
Invoke-LabCommand -ComputerName Web1 -ScriptBlock {
    Get-ADUser -Identity John
}
```
#### Running scripts with context

In case you need to run code with some additional files present, be sure to place those files in a single directory. It is then transferred to the VMs by using
the parameter `DependencyFolderPath`! The dependency folder does not need to contain your script. It will always be copied the OS root, e.g. `/` on Linux and `C:\` on Windows.

```powershell
## Run the script ./ConfigureSomeAgent.ps1 and send the directory $labsources/Tools/SomeAgentFiles to the VM
Invoke-LabCommand -FilePath ./ConfigureSomeAgent.ps1 -PassThru -ComputerName (Get-LabVm) -DependencyFolderPath $labsources/Tools/SomeAgentFiles
```

### Transferring modules to machines
Invoke-LabCommand is a comfortable way to run scripts and ScriptsBlocks defined on your host machine in any lab machine. This cmdlet takes care of the authentication and allows you to send variables and functions to the remote machine. But how can you use cmdlets defined in a PowerShell module that exists on your host machine in a lab VM? With Send-ModuleToPSSession we have provided a way to send any PowerShell module available locally to a lab VM. 

Note: This cmdlet makes use of other functions provided within the AutomatedLab framework to copy files to Hyper-V or Azure machines like Send-Directory and what is provided by the [PSFileTransfer]( https://github.com/AutomatedLab/AutomatedLab/tree/master/PSFileTransfer) module.

Send-ModuleToPSSession will try to send the module using SMB first and if this does not work, using the PSSession.
The module will be copied either to the Program Files\WindowsPowerShell\Modules or to the module path of the user used for opening the PSSession, depending of the scope you set: AllUsers, CurrentUser.
There is also a switch to look for all module dependencies and copy them as well.

### Demo (Problem)
The following code block demos the problem. You have a module locally on your machine and have successfully tested some code. Now you want to invoke that code on all lab machines (Azure or Hyper-V) but the module is not there yet.

``` PowerShell
Import-Lab -Name POSH -NoValidation

##works locally
Get-NTFSAccess -Path C:\

##does not work remotely unless the module has been copied to the machines
$vms = Get-LabVM -Role ADDS
Invoke-LabCommand -ScriptBlock { Get-NTFSAccess -Path C:\ } -ComputerName $vms
```

The error is

```
The term 'Get-NTFSAccess' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
    + CategoryInfo          : ObjectNotFound: (Get-NTFSAccess:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
    + PSComputerName        : POSHDC1
 
The term 'Get-NTFSAccess' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
    + CategoryInfo          : ObjectNotFound: (Get-NTFSAccess:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

### Demo (Solution)
It requires just one additional line and you can use your local module on the remote machines and this is, how it works:
1. You deploy your lab or import an import an existing one
2. You create a new PSSession to one or more machines
3. You send the module to these sessions
4. Then you can use the module on the lab VM

After using Send-ModuleToPSSession, everything works as desired.

``` PowerShell
Import-Lab -Name POSH -NoValidation

##works locally
Get-NTFSAccess -Path C:\

$vms = Get-LabVM -Role ADDS

##just one line is required to copy the module to the VMs
Send-ModuleToPSSession -Module (Get-Module -Name NTFSSecurity -ListAvailable) -Session (New-LabPSSession -ComputerName $vms)

##now works remotely 
Invoke-LabCommand -ScriptBlock { Get-NTFSAccess -Path C:\ } -ComputerName $vms -PassThru
```
## Join Lab VMs to an existing domain

AutomatedLab can deploy in your existing infrastructure with very little modifications necessary. At the moment, this is supported for existing domains only, but may be extended in the future.

The `Add-LabMachineDefinition` cmdlet can make use of the `SkipDeployment` parameter in order to add an existing domain controller to your lab. You could for example locate an existing DC to join to:  
```powershell
$DomainName = 'janhendrikpeters.de'
$ctx = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $DomainName)
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
$dc = $domain.FindDomainController([System.DirectoryServices.ActiveDirectory.LocatorOptions]::WriteableRequired).Name
$dcName = $dc.Replace(".$DomainName", '')
$dcIp = [System.Net.Dns]::GetHostAddresses($dc).IpAddressToString
```  

Now in order to add your domain controller, simply supply the host name and IP address of the system, as well as the domain join credentials:

```powershell
$DomainJoinCredential = Get-Credential
Set-LabInstallationCredential -Username ($DomainJoinCredential.UserName -split '\\')[-1] -Password $DomainJoinCredential.GetNetworkCredential().Password
## We are not using a domain admin as we skip the deployment of the DC. Nevertheless, this credential is used for domain joins.
Add-LabDomainDefinition -Name $DomainName -AdminUser ($DomainJoinCredential.UserName -split '\\')[-1] -AdminPassword $DomainJoinCredential.GetNetworkCredential().Password

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = $DomainName
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server Datacenter'
    'Add-LabMachineDefinition:Memory' = 512MB
}

Add-LabMachineDefinition -Name $dcName -Roles RootDc -SkipDeployment -IpAddress $dcIp
Add-LabMachineDefinition -Name POSHFS01
Add-LabMachineDefinition -Name POSHWEB01

Install-Lab
```

The full sample script can be found in [the SampleScripts folder](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/SampleScripts/Scenarios/ExistingDomainLab.ps1).

Stay tuned!
Once installed, a lab can still be modified to some extent. As a general rule of thumb: Changes
that the product does not support, AutomatedLab does not support as well. For example, you cannot
change the domain that has been deployed after the installation without first removing the Domain Controller
VMs.

### Add and remove machines

An AutomatedLab is defined by several XML files we export in the background. Those can
be modified to some extent by AutomatedLab cmdlets.

To remove a VM, import the lab first, then remove it:

```powershell
Import-Lab -Name YourLab -NoValidation # NoValidation - fast import, because we don't need validation to run every time
Remove-LabVm -Name YourMachine # That is enough to remove the resource
```

To modify a deployment, either:
 
```powershell
Import-LabDefinition -Name YourLab
Add-LabMachineDefinition -Name newMachine
Remove-LabMachineDefinition -Name AnotherMachine
Install-Lab
```

or add the machine definitions in your original script - AutomatedLab detects if a role has been deployed and skips it. As long
as you do not intend to change key settings, like the domain that is getting deployed, you can simply rerun the same script after
you have added a couple of machines.

### 2 - Deploy labs that use existing lab infrastructure

Labs can be installed into existing infrastructure. While there is no general way of doing this,
a few pointers are:

- Take care of networking - usually, existing on-premises components will be reached by connecting
  the lab VMs to an external switch. This can be added using `Add-LabVirtualNetworkDefinition -HyperVProperties @{SwitchType = 'External'}
- Add references to roles like Domain Controllers using the `SkipDeployment` parameter
- Include the required credentials to connect to machines referenced using the `SkipDeployment` parameter!

Want to connect a lab using an IPSEC VPN? Maybe take a look at [this sample](../SampleScripts/Azure/en-us/VpnConnectedLab.md).

```powershell
New-LabDefinition -Name ConnectToEnv -DefaultVirtualizationEngine HyperV
Add-LabDomainDefinition -Name contoso.com -AdminUser admin -AdminPassword 'S00perS3cure!'
Add-LabVirtualNetworkDefinition -Name prodnet -AddressSpace 10.0.1.0/24 -HyperVProperties @{SwitchType = 'External'; AdapterName = '10GB'}
Add-LabMachineDefinition -Name DC1 -DomainName contoso.com -Role RootDc -SkipDeployment -IpAddress 10.0.1.101
Add-LabMachineDefinition -Name MS1 -DomainName contoso.com -Network prodnet -IpAddress 10.0.1.10
Install-Lab
```
Mounting ISO files on Azure is as simple as calling the existing cmdlet ``Mount-LabIsoImage``. The only difference is that the ISO image file path lies on Azure. To find out which images are accessible in your AutomatedLab storage account you can do the following:

    Login-AzureRmAccount
    (Get-LabAzureLabSourcesContent -RegexFilter \.iso).FullName

When mounting the ISO file, be sure to specify `-PassThru` to be able to use the drive letter that was used to mount the ISO in later commands:

    $mountedVolume = Mount-LabIsoImage -IsoPath https://some/azure/path.iso -ComputerName DC1 -PassThru

    Invoke-LabCommand DC1 -ScriptBlock {
    param
    (
        $DriveLetter
    )

        Start-Process (Join-Path $DriveLetter "Path\To\My\Setup.exe")
    } -ArgumentList $mountedVolume.DriveLetter
AutomatedLab can handle everything about networking and IP addresses automatically for you. But, if you prefer, you can define everything by your own. AL supported also working with multiple subnets and internet connected labs. It takes care about the routing if a machine with the role 'Routing' is defined in the network.

### Fully automated

AutomatedLab tries to make defining and deploying labs as easy as possible. Quite often you need some machines that can talk to each other but you are not interested in the IP configuration. In this case you do not have to care about networking and IP addresses at all. AL defines the virtual switch for you and also finds a free subnet for you.

If you take a look at the introduction script [[04 Single domain-joined server.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Introduction/04%20Single%20domain-joined%20server.ps1) you will not find anything that defines a network. When deploying the lab AL tells you the subnet that was chosen.

AL tries to find new subnets by simply increasing 192.168.1.0 until a free network is found. Free means that there is no virtual network switch with an IP address in the range of the subnet and the subnet is not routable. If these conditions are not met, the subnet is incremented again. 

### Simple network definition

To manually create network definitions in order to have specific network address ranges available, the cmdlet ``Add-LabVirtualNetworkDefinition`` can be used for both HyperV- and Azure-based labs.

```powershell
    # Adds a virtual network with no special options
    Add-LabVirtualNetworkDefinition -Name 'MySimpleNetwork' -AddressSpace 10.1.0.0/16  
```

Additionally, the parameters AzureProperties and HyperVProperties can be used to pass parameter hashtables. The following are valid keys that can be used as properties for AzureProperties:

* SubnetName: The name of the subnet to create in the virtual network. AL does not segment virtual networks into subnets. One virtual network per network definition will be created
* SubnetAddressPrefix: The address prefix (e.g. 24) of the subnet that will be created.
* LocationName: The Azure location name (e.g. westeurope). Bear in mind that this should not differ from your lab's default location.
* DnsServers: Comma-separated DNS servers for the network.
* ConnectToVnets: Connections to other Lab VNETs by leveraging VNET peering. When connecting two or more lab networks through this parameter, please also specifiy this for all additional network definitions
* PeeringVnetResourceIds: Connections to VNETs not managed by AutomatedLab. A list of resource IDs for the peering is required in the form /subscriptions/<GUID>/resourceGroups/<RGNAME>/providers/Microsoft.Network/virtualNetworks/<VNETNAME>. All peerings will be created with VNET access, no GW transit, no forwarding and no remote gateways.

For HyperV, the following properties are valid:

* SwitchType: Internal or External. Defaults to internal. If External is specified, AdapterName needs to be set as well
* AdapterName: The network adapter of the OS that will bridge the connection to the external network

### Simple internet connected

Reviewing the HyperV and Azure properties for ``Add-LabVirtualNetworkDefinition`` we can see that internet-connected virtual networks can easily be created.

To enable HyperV labs to have an internet connection, the following syntax can be used:  
```powershell
    Add-LabVirtualNetworkDefinition -Name 'MySimpleConnectedNetwork' -AddressSpace 10.1.0.0/16 -HyperVProperties @{SwitchType = 'External'; AdapterName = 'Ethernet'}
```

This is all it takes for machines to connect to the internet.

Azure networks by default are connected to the internet through a load balancer that initially only gives access to WinRM and RDP. Through NAT rules random external ports are mapped to the ports 5985, 5986 and 3389 on each machine. The random ports are stored for each machine, so that all connection-related cmdlets like ``Enter-LabPSSession`` or ``Connect-LabVm`` work transparently.

Additionally, Azure RDP files can be created by using ``Get-AzureRmRemoteDesktopFile``.

### Complex internet connected

here be dragons.
While creating an Azure-based lab is very easy and only requires to set the default virtualization engine to Azure instead of HyperV. Not all features are readily available from the start. To fully make use of Azure, you should also synch your lab sources with Azure. Doing so only requires a single line of code: `Sync-LabAzureLabSources`.

This by default will synchronize your entire local lab sources folder with a pre-created Azure file share called labsources in the resource group AutomatedLabSources and the lab's randomly-named storage account. This file share will automatically be mapped on each virtual machine.  
Operating system images are automatically skipped in the synchronization process as they are readily available on Azure and are not being used.

During the lab initialization the builtin variable $labSources will be automatically updated to point to your Azure lab sources location if you are deploying an Azure-based lab. There is no need to declare the variable in any script, as it is dynamically calculated to match the default virtualization engine.

To skip large files or entire ISOs for certain products like e.g. Exchange or Skype for Business the following parameters are available:

* SkipIsos: This switch parameter indicates that all ISO files should be skipped.
* MaxFileSizeInMb: This parameter takes an integer value indicating the maximum size of the files to synch.

Now you can simply use the other cmdlets provided by AutomatedLab to access files from the file share:

* `$postInstallActivity = Get-LabPostInstallationActivity -ScriptFilePath $labSources\PostInstallationActivities\PrepareRootDomain\PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain`
* `Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob`
## Using Azure Bastion Hosts

Azure Bastion Hosts are in preview as of 2020-05-19 and allow you to connect to your lab machines
via the Remote Desktop Web Client from an Azure Bastion. Starting with release 5.21 AutomatedLab
supports these as well.

When opting to deploy a bastion, note that this will increase the time your lab deployment takes.
This is due to:
  - The resource provider feature AllowBastionHost takes time to activate, if it is not registered.
    (***This step can take up to 20 minutes!***)
  - The resource group deployment eventually takes up to five minutes longer

### Usage

The easiest way to add a Bastion to your lab is by using the new AllowBastionHost parameter:  

```powershell
New-LabDefinition -Name Bastion1 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName JHPaaS -DefaultLocationName 'West Europe' -AllowBastionHost

Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary
```  

Specifying this parameter will mean that your virtual network is extended to accomodate the bastion
host subnet. Additionally, the lab network security group will receive additional rules.

### More control with custom subnets

If you do not want to extend the virtual network you defined in your lab, you can simply add a
bastion subnet called AzureBastionSubnet - AutomatedLab will take care of the rest.

```powershell
New-LabDefinition -Name Bastion2 -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -SubscriptionName JHPaaS -AllowBastionHost -DefaultLocationName 'West Europe'

Add-LabVirtualNetworkDefinition -Name Lab2Vnet -AddressSpace 192.168.10.0/23 -AzureProperties @{ Subnets = @{
    'default' = '192.168.10.0/24'
    'AzureBastionSubnet' = '192.168.11.0/24'
}}
Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC -DomainName contoso.com -Network Bastion2Vnet -IpAddress 192.168.10.11

Install-Lab

Show-LabDeploymentSummary
```

### Connecting via the Bastion

At the moment, you need to use the [Azure portal](https://portal.azure.com) to connect to your bastion host. In the future, we might be able to use Connect-LabVm instead.
