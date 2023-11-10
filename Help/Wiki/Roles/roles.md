There are some predefined roles in AutomatedLab that can be assigned to a machine. A machine can have none, one or multiple roles. Some roles are mutually exclusive like RootDC and FirstChildDC, or SQLSevrer2008 and SQLServer2012.

Roles can be assigned in two ways. The first and most simple is this one. However, it does not allow any customization:

```powershell
Add-LabMachineDefinition -Name DC1 -Roles RootDC
Add-LabMachineDefinition -Name CA1 -Roles CaRoot, Routing
Add-LabMachineDefinition -Name Web1 -Roles WebServer
```

Many roles offer options for customization. The options are documented in the role documentation. If you want to define a customized role, use the cmdlet Get-LabMachineRoleDefinition which takes two parameters, the role and properties. The properties parameter takes a hashtable.
If you want to define the role FirstChildDC, you can leave everything to default / automatics or go with your own definition.
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
The list of available roles in AutomatedLab is below. Of course, there are many products missing. AutomatedLab offers a lot of features that makes it a good basis for adding roles to it or implementing new roles in separate projects that are based on AutomatedLab. A good example for this is SfBAutomatedLab. Skype for Business role model is too complex to be added to AL. But AL was used for deploying the VMs, OS, AD, SQL, PKI, etc. The Skype for Business roles are installed using the cmdlet Invoke-LabCommand, Install-LabSoftwarePackage and Mount- / Dismount-LabIsoImage. You may want to check out the [project on GitHub](https://github.com/AutomatedLab/SfBAutomatedLab).

### List of Roles
- ADFS
- ADFSProxy
- ADFSWAP
- [AzDevOps](cicd.md)
- CaRoot
- CaSubordinate
- [ConfigurationManager](configurationmanager.md)
- [DC](activedirectory.md)
- DHCP
- [DSCPullServer](dscpull.md)
- [DynamicsAdmin](dynamics365.md)
- [DynamicsBackend](dynamics365.md)
- [DynamicsFrontend](dynamics365.md)
- [DynamicsFull](dynamics365.md)
- [FailoverNode](failoverclustering.md)
- [FailoverStorage](failoverclustering.md)
- FileServer
- [FirstChildDC](activedirectory.md)
- [HyperV](hyperv.md)
- RemoteDesktopConnectionBroker
- RemoteDesktopGateway
- RemoteDesktopLicensing
- RemoteDesktopSessionHost
- RemoteDesktopVirtualizationHost
- RemoteDesktopWebAccess
- [RootDC](activedirectory.md)
- Routing
- ScomConsole
- ScomGateway
- ScomManagement
- ScomReporting
- ScomWebConsole
- [Scvmm2016](scvmm.md)
- [Scvmm2019](scvmm.md)
- [Scvmm2022](scvmm.md)
- [SharePoint2013](sharepoint.md)
- [SharePoint2016](sharepoint.md)
- [SharePoint2019](sharepoint.md)
- [SQLServer2008](sql.md)
- [SQLServer2008R2](sql.md)
- [SQLServer2012](sql.md)
- [SQLServer2014](sql.md)
- [SQLServer2016](sql.md)
- [SQLServer2017](sql.md)
- [SQLServer2019](sql.md)
- [SQLServer2022](sql.md)
- [Tfs2015](cicd.md)
- [Tfs2017](cicd.md)
- [Tfs2018](cicd.md)
- [TfsBuildWorker](cicd.md)
- VisualStudio2013
- VisualStudio2015
- WebServer
- WindowsAdminCenter