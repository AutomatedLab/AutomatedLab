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
