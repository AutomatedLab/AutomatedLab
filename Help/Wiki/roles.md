There are some predefined roles in AutomatedLab that can be assigned to a machine. A machine can have none, one or multiple roles. Some roles are mutually exclusive like RootDC and FirstChildDC, or SQLSevrer2008 and SQLServer2012.

Roles can be assigned in two ways. The first and most simple is this one. However, it does not allow any customization:

```powershell
Add-LabMachineDefinition -Name DC1 -Roles RootDC
Add-LabMachineDefinition -Name CA1 -Roles CaRoot, Routing
Add-LabMachineDefinition -Name Web1 -Roles WebServer
```

Many roles offer options for customization. The options are documented in the role documentation. If you want to define a customized role, use the cmdlet Get-LabMachineRoleDefinition which takes two parameters, the role and properties. The properties parameter takes a hashtabe.
If you want to define the fole FirstChildDC, you can leave everything to default / automatics or go with your own definition.
```powershell
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'vm.net'; NewDomain = 'a'; DomainFunctionalLevel = 'Win2012R2' }
Add-LabMachineDefinition -Name T3ADC1 -IpAddress 192.168.50.20 -DomainName a.vm.net -Roles $role
```

And another example that defines the Exchange 2013 role with an organization name defined:

```powershell
$role = Get-LabMachineRoleDefinition -Role Exchange2013 -Properties @{ OrganizationName = 'TestOrg' }
Add-LabMachineDefinition -Name T3AEX1 -Memory 4GB -IpAddress 192.168.50.52 -DomainName a.vm.net -Roles $role -DiskName ExDataDisk
```

## Available Roles
The list of available roles in AutomatedLab is below. Of course, there are many products missing. AutomatedLab offers a lot of features that makes it a good basis for adding roles to it or implementing new roles in separate projects that are based on AutomatedLab. A good example for this is SfBAutomatedLab. Skype for Business role model is too complex to be added to AL. But AL was used for deploying the VMs, OS, AD, SQL, PKI, etc. The Skype for Business roles are installed using the cmdlet Inovke-LabCommand, Install-LabSoftwarePackage and Mount- / Dismount-LabIsoImage. You may want to check out the [project on GitHub](https://github.com/AutomatedLab/SfBAutomatedLab).

### List of Roles
- RootDC
- FirstChildDC
- DC
- ADDS
- FileServer
- WebServer
- DHCP
- Routing
- CaRoot
- CaSubordinate
- SQL Server2008
- SQL Server2008 R2
- SQL Server2012
- SQL Server2014
- SQL Server2016
- SQL Server 2019
- VisualStudio2013
- VisualStudio2015
- SharePoint2013
- SharePoint2016
- SharePoint2019
- Orchestrator2012
- Exchange2013
- Exchange2016
- Office2013
- Office2016
- ADFS
- ADFSWAP
- ADFSProxy
- DSCPullServer
- HyperV
- TFS2015, 2017, 2018, Azure DevOps (Server as well as cloud service)

## Active Directory

For Active Directory AutomatedLab provides three roles: RootDC, FirstChildDC and DC. AL knows about standard parameters for all roles but allows a fair amount of customization.
AL supports multi-forest and / or multi-domain environments in a single lab. AL will try to get the number of domains to add from the definition of domain controllers. AL auto-detects domains in a simple environment. If your lab is more complex, it is recommended to define the domains manually using the cmdlet Add-LabDomainDefinition.
Some more documentation on the parameters is down below.

### Root Domain Controllers (RootDC)
Each forest starts with a Root Domain Controller. The number of forests in your lab is defined by the number of machines with the role RootDC and by the domains you are assigning these machines to. Having two Root Domain Controllers in a domain results in an error.
The role RootDC supports the following parameters for customizations: SiteName, SiteSubnet, DomainFunctionalLevel and ForestFunctionalLevel.

#### Role Assignment
The simple assignment that takes the default settings:
```powershell
Add-LabMachineDefinition -Name DC1 -OperatingSystem 'Windows 2016 SERVERDATACENTER' -Roles RootDC
```
The next example demonstrates the usage of all available parameters:
```powershell
$role = Get-LabMachineRoleDefinition -Role RootDC @{
    ForestFunctionalLevel = 'Win2012R2'
    DomainFunctionalLevel = 'Win2012R2'
    SiteName = 'Frankfurt'
    SiteSubnet = '192.168.10.0/24'
}
Add-LabMachineDefinition -Name T3RDC1 -IpAddress 192.168.10.10 -DomainName contoso.com -Roles $role
```
### First Child Domain Controller (FirstChildDC)
If you need a child domain or a new tree in your forest, you start with assigning this role to a machine. Like for the RootDC role AL tries to auto-detect missing data, like the root domain. If you assign a role FirstChildDC to a machine which is in the domain child.contoso.com, AL take contoso.com as the parent domain. If you are running more than one forest in a lab, this cannot work anymore and some more data is required.
This role needs to know about the name of the new child domain or domain tree and the parent domain name. If this cannot be retrieved automatically, an error is thrown.

#### Role Assignment
The simple example for this role looks identical with the one for the role RootDC. The next example demonstrates all available parameters:

```powershell
$role = Get-LabMachineRoleDefinition -Role FirstChildDC @{
    ParentDomain = 'contoso.com'
    NewDomain = 'emea'
    DomainFunctionalLevel = 'Win2012R2'
    SiteName = 'London'
    SiteSubnet = '192.168.50.0/24'

}
Add-LabMachineDefinition -Name LDC1 -IpAddress 192.168.50.10 -DomainName emea.contoso.com -Roles $role
```
### Domain Controller (DC)
This role can be assigned to a machine to become an additional domain controller in a root or child domain defined earlier. You cannot have the role DC without having also the role RootDC or FirstChildDC. 
This role supports the parameters SiteName, SiteSubnet and ReadOnly

#### Role Assignment
Using all these parameters looks like this:
```powershell
$role = Get-LabMachineRoleDefinition -Role DC @{
    SiteName = 'Milano'
    SiteSubnet = '192.168.60.0/24'
    IsReadOnly = 'true'
}
Add-LabMachineDefinition -Name RODC1 -IpAddress 192.168.60.10 -DomainName emea.contoso.com -Roles $role
```

### Installation Process
The installation is done when calling 'Install-Lab' without using additional parameters. To start only the Active Directory installation, you can use 'Install-Lab -Domains’.

### Requirements
This role cannot be assigned to a client OS. The only additional requirement is to provide the correct data if AL cannot discover your intended setup automatically.

### Parameters
#### ForestFunctionalLevel (RootDC)
This value is only available for the RootDC role and takes the Forest Functional Level. Valid values are
- Win2008R2
- Win2012
- Win2012R2
- WinThreshold (Win2016)

#### DomainFunctionalLevel (RootDC and FirstChildDC)
This value is available on the roles RootDC and FirstChildDC and controls the Domain Functional Level. Valid values are
- Win2008R2
- Win2012
- Win2012R2
- WinThreshold (Win2016)

#### SiteName
When defined, AL creates the given site after promoting the domain controller and moves the domain controller into that site.

#### DatabasePath
Stores the AD database files in the given folder.

#### LogPath
Stores the AD log files in the given folder.

#### SysvolPath
Stores the Sysvol folder in the given folder

#### DsrmPassword
When defined, set the Directory Services Restore Mode password to something different than the lab's install user's password.

#### SiteSubnet
When defined, AL creates a new Active Directory Replication subnet and assigns it to the site creates previously. The parameter SiteSubnet requires SiteName to be defined.

#### IsReadOnly (DC)
This string parameter makes the domain controller a read-only domain controller. Use 'true' to enable the ReadOnly DC role.

#### NewDomain (FirstChildDC)
Defines the new domain name for the FirstChildDC. If this value is a FQDN, AL creates a new domain tree, in case of a short name a child domain is created.

#### ParentDomain (FirstChildDC)
This specifies the root domain the new domain should be located in. The parameter takes the full FQDN.

## Office 2013 and Office 2016

The Office 2013 Role is installing Office 2013 in a predefined standard configuration. If not customized, Office 2013 is installed in the computer licensing mode. There is an option to switch to shared computer activation.

## Role Assignment
The role can be assigned to a machine like this:
```powershell
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles Office2013
```

## Installation Process
The installation is covered when calling 'Install-Lab' without using additional parameters. To start only the Office 2013 installation, you can use 'Install-Lab -Office2013'.

## Requirements
In order to install this role, the Office 2013 ISO image needs to be added to the lab. Adding the ISO works like this:

```powershell
Add-LabIsoImageDefinition -Name Office2013 -Path E:\LabSources\ISOs\en_office_professional_plus_2013_with_sp1_x86_dvd_3928181.iso
```

The Office 2016 Role is installing Office 2016 in a predefined standard configuration. If not customized, Office 2016 is installed in the computer licensing mode. There is an option to switch to shared computer activation.

## Role Assignment
The role can be assigned directly to a machine like this:
```powershell
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles Office2016
```
Or if you want to change the licensing option, the role needs to be created first by means of Get-LabMachineRoleDefinition:
```powershell
$role = Get-LabMachineRoleDefinition -Role Office2016 -Properties @{ SharedLicense = $true }
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles $role
```

## Installation Process
The installation is covered when calling 'Install-Lab' without using additional parameters. To start only the Office 2016 installation, you can use 'Install-Lab -Office2016'.

## Requirements
In order to install this role, the Office 2016 ISO image needs to be added to the lab. Adding the ISO works like this:

```powershell
Add-LabIsoImageDefinition -Name Office2016 -Path E:\LabSources\ISOs\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso
```

## Failover Clustering
More and more roles support failover clusters. Thus, testing e.g. SQL AlwaysOn and other scenarios is something that you will need a cluster for. AutomatedLab 4.5 and newer is able to deploy one or more clusters for you. Depending on the OS version, you are able to deploy multidomain or workgroup clusters as well, without any work on your part except for selecting two or more machines.  
### Cluster  
AutomatedLab can help you set up one or more failover clusters starting with Server 2008 R2. All you need to do is select the role FailoverNode for at least two of your machines.  

```powershell
# Simple cluster with auto-generated name ALCluster and auto-generated IP
Add-LabMachineDefinition -Name focln1 -Roles FailoverNode
Add-LabMachineDefinition -Name focln2 -Roles FailoverNode
```  
The role properties allow you to customize your cluster and to create more than one cluster.  
```powershell
# Two clusters
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111' }
$cluster2 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu2'; ClusterIp = '192.168.50.121' }
Add-LabMachineDefinition -Name focln11 -Roles $cluster1
Add-LabMachineDefinition -Name focln12 -Roles $cluster1

Add-LabMachineDefinition -Name focln21 -Roles $cluster2
Add-LabMachineDefinition -Name focln22 -Roles $cluster2
```

### Storage  
In case you want your cluster to use a disk witness or generally experiment with storage in your clusters, you can select to deploy an iSCSI target with the new role FailoverStorage. A target will be created for each cluster, permitting only the cluster nodes to connect to it. During cluster setup, a disk witness will automatically be used for your cluster.  
```powershell
# Deploy iSCSI Target server with enough storage for your witness disks (1GB/cluster)
$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage -Properties @{LunDrive = 'D' }
Add-LabDiskDefinition -Name LunDisk -DiskSizeInGb 26
Add-LabMachineDefinition -Name foCLS1 -Roles $storageRole -DiskName LunDisk

# Deploy your cluster
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu2'; ClusterIp = '192.168.50.111' }
Add-LabMachineDefinition -Name focln11 -Roles $cluster1
Add-LabMachineDefinition -Name focln12 -Roles $cluster1
Add-LabMachineDefinition -Name focln13 -Roles $cluster1
```

## SharePoint Server

The roles SharePoint2013, SharePoint2016 and SharePoint2019 enable you to install SharePoint in a single server configuration.
All preqrequisites are downloaded automatically, but can be prepared easily in an offline scenario.

In order to really deploy SharePoint according to your needs, consider using [SharePointDsc](https://github.com/dsccommunity/SharePointDsc) with ```Invoke-LabDscConfiguration```.

### Prerequisites

We store a list of prerequisites with PSFramework, which means that you can customize this setting or use it to download
and prepare the prerequisites! To do that, you can find a list of URIs with ```Get-LabConfigurationItem SharePoint2016Prerequisites # Adjust to your version```.

Simply store the downloaded files without renaming them in ```$labsources\SoftwarePackages\SharePoint2016 # Adjust to your version```. All files are picked up automatically even when no connection is available.

## CI/CD Pipeline

AutomatedLab now also lets you create release pipelines inside your lab by making use of AutomatedLab.Common's new TFS cmdlets.
### The lab
Your lab should include at least one TFS 2017 server and a suitable SQL 2016 server. You can use the sample provided at [DSC with release pipeline](https://github.com/AutomatedLab/AutomatedLab/blob/master/LabSources/SampleScripts/Scenarios/DSC%20With%20Release%20Pipeline.ps1).  
```powershell
Add-LabMachineDefinition -Roles Tfs2017
Add-LabMachineDefinition -Roles TfsBuildWorker # Optional, directly adds build workers to your TFS agent pools
```
### The pipeline
Before starting you should have an understanding of what a release pipeline is. There are plenty of resources out there. Especially for DSC, you could have a look [here](https://docs.microsoft.com/en-us/powershell/dsc/dsccicd).  
To add a new pipeline in AutomatedLab, there are only two cmdlets.
#### Get-LabBuildStep
This cmdlet lists all available build steps that you can configure since there is not much documentation available. The output of Get-LabBuildStep can be copied and pasted with the correct formatting to use with New-LabReleasePipeline.
#### New-LabReleasePipeline
This cmdlet goes through the necessary steps to create a new CI/CD pipeline. A project will be created, if specified a git repository will be forked and pushed to the new team project's repository and the build definition will be created.  
The build definition is the only thing that requires some though. Since a build definition consists of multiple build steps you will need to select for yourself which steps might make sense.
```powershell
$buildSteps = @(
    @{
        "enabled"         = $true
        "continueOnError" = $false
        "alwaysRun"       = $false
        "displayName"     = "Execute Build.ps1"
        "task"            = @{
            "id"          = "e213ff0f-5d5c-4791-802d-52ea3e7be1f1"
            "versionSpec" = "*"
        }
        "inputs"          = @{
            scriptType          = "filePath"
            scriptName          = ".Build.ps1"
            arguments           = "-resolveDependency"
            failOnStandardError = $false
        }
    }
)

# Clone the DSCInfraSample code and push the code to TFS while creating a new Project and the necessary build definitions
New-LabReleasePipeline -ProjectName 'ALSampleProject' -SourceRepository https://github.com/gaelcolas/DSCInfraSample -BuildSteps $buildSteps
```  
The ID you can see in the little code sample refers to the build step ID - this is part of the output of ``` Get-LabBuildStep ```:
```powershell
@{
            enabled         = True
            continueOnError = False
            alwaysRun       = False
            displayName     = 'YOUR OWN DISPLAY NAME HERE' # e.g. Archive files $(message) or Archive Files
            task            = @{
                id          = 'd8b84976-e99a-4b86-b885-4849694435b0'
                versionSpec = '*'
            }
            inputs          = @{
                                rootFolder = 'VALUE' # Type: filePath, Default: $(Build.BinariesDirectory), Mandatory: True
                                includeRootFolder = 'VALUE' # Type: boolean, Default: true, Mandatory: True
                                archiveType = 'VALUE' # Type: pickList, Default: default, Mandatory: True
                                tarCompression = 'VALUE' # Type: pickList, Default: gz, Mandatory: False
                                archiveFile = 'VALUE' # Type: filePath, Default: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip, Mandatory: True
                                replaceExistingArchive = 'VALUE' # Type: boolean, Default: true, Mandatory: True

            }
        }
```