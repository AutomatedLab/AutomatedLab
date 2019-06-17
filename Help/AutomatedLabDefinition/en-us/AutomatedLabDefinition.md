---
Module Name: AutomatedLabDefinition
Module Guid: e85df8ec-4ce6-4ecc-9720-1d08e14f27ad
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLabDefinition Module
## Description

The AutomatedLabDefinition module is the starting point for your lab deployments.
All labs start with a new lab definition, and should contain at least one machine definition.

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