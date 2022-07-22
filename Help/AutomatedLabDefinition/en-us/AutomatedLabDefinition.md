---
Module Name: AutomatedLabDefinition
Module Guid: e85df8ec-4ce6-4ecc-9720-1d08e14f27ad
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLabDefinition Module
## Description
The AutomatedLabDefinition module is the starting point for your lab deployments. All labs start with a new lab definition, and should contain at least one machine definition.
Optionally can add network, domain, disk and more definitions.
Take the following example:

```powershell
# Start with the lab definition to declare the Hypervisor
Add-LabDefinition -Name MyLab -DefaultVirtualizationEngine HyperV

# List the available operating systems, after executing Add-LabDefinition
Get-LabAvailableOperatingSystem

# Optionally add a domain
Add-LabDomainDefinitiion -Name contoso.com -AdminUser Administrator -AdminPassword Somepass1

# Add a domain controller as a Windows Server 2016 Core server
# The role alone is enough to deploy the single-domain forest contoso
Add-LabMachineDefinition -Name DC01 -Role RootDC -OperatingSystem 'Windows Server 2016 Datacenter'

# To deploy the lab definition (Think: Desired State Configuration - Push)
Install-Lab
```

## AutomatedLabDefinition Cmdlets
### [Add-LabAzureAppServicePlanDefinition](Add-LabAzureAppServicePlanDefinition.md)


### [Add-LabAzureWebAppDefinition](Add-LabAzureWebAppDefinition.md)


### [Add-LabDiskDefinition](Add-LabDiskDefinition.md)
Add lab disk definition

### [Add-LabDomainDefinition](Add-LabDomainDefinition.md)
Add a definition of an Active Directory domain or forest to the lab

### [Add-LabIsoImageDefinition](Add-LabIsoImageDefinition.md)
Adds a definition of an ISO file using a logical name and a path of the ISO file

### [Add-LabIsoImageDefinition](Add-LabIsoImageDefinition.md)
Adds a definition of an ISO file using a logical name and a path of the ISO file

### [Add-LabVirtualNetworkDefinition](Add-LabVirtualNetworkDefinition.md)
Adds a definition of a virtual network

### [Export-LabDefinition](Export-LabDefinition.md)
Export lab as XML

### [Get-DiskSpeed](Get-DiskSpeed.md)
Measures the disk speed of the specified logical drive letter

### [Get-LabAvailableAddresseSpace](Get-LabAvailableAddresseSpace.md)
Get available address space

### [Get-LabAzureAppServicePlanDefinition](Get-LabAzureAppServicePlanDefinition.md)


### [Get-LabAzureWebAppDefinition](Get-LabAzureWebAppDefinition.md)


### [Get-LabDefinition](Get-LabDefinition.md)
Gets the lab definition

### [Get-LabDomainDefinition](Get-LabDomainDefinition.md)
Returns all definitions of Active Directory domains/forest in the lab

### [Get-LabInstallationActivity](Get-LabInstallationActivity.md)
Get pre/post-installation activity

### [Get-LabIsoImageDefinition](Get-LabIsoImageDefinition.md)
Returns all ISO definitions in the lab

### [Get-LabMachineDefinition](Get-LabMachineDefinition.md)
Returns all machine definitions in the lab

### [Get-LabMachineRoleDefinition](Get-LabMachineRoleDefinition.md)
Get a role definition

### [Get-LabPostInstallationActivity](Get-LabPostInstallationActivity.md)
Get post-installation activity

### [Get-LabVirtualNetwork](Get-LabVirtualNetwork.md)
Returns all existing virtual networks (switches) on a Hyper-V host

### [Get-LabVirtualNetworkDefinition](Get-LabVirtualNetworkDefinition.md)
Returns all virtual network definitions in the lab

### [Get-LabVolumesOnPhysicalDisks](Get-LabVolumesOnPhysicalDisks.md)
Get lab volumes

### [Import-LabDefinition](Import-LabDefinition.md)
Import an existing lab definition to extend it later on.

### [New-LabDefinition](New-LabDefinition.md)
Creates a new lab definition

### [New-LabNetworkAdapterDefinition](New-LabNetworkAdapterDefinition.md)
Creates a network adapter definition roughly interpreted as a NIC

### [Remove-LabDomainDefinition](Remove-LabDomainDefinition.md)
Remove a domain definition

### [Remove-LabIsoImageDefinition](Remove-LabIsoImageDefinition.md)
Remove ISO definition

### [Remove-LabMachineDefinition](Remove-LabMachineDefinition.md)
Remove a machine definition

### [Remove-LabVirtualNetworkDefinition](Remove-LabVirtualNetworkDefinition.md)
Remove a virtual network definition

### [Repair-LabDuplicateIpAddresses](Repair-LabDuplicateIpAddresses.md)
Repair duplicate IPs

### [Set-LabDefinition](Set-LabDefinition.md)
{{ Fill in the Synopsis }}

### [Set-LabLocalVirtualMachineDiskAuto](Set-LabLocalVirtualMachineDiskAuto.md)
Set the VM disk container

### [Test-LabDefinition](Test-LabDefinition.md)
Validates the lab definition

