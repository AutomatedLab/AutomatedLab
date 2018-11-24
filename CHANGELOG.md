# Changelog

## Unreleased

- Fixed SQL Setup (2016+) by preinstalling C++ redist

## 5.0.4 - 2019-09-28

### Enhancements

- Get-DiskSpace includes UNC paths
- Windows 10 Enterprise support for remote sessions
- Workflows replaced with functions
- Runspace cmdlets added to AutomatedLab.Common
- Azure subscription handling updated

### Fixes

- PowerCLI fixes
- Error handling in Get-LabIssuingCa
- Issues with Azure domain joins fixed
- Issues with Azure subscription usage fixed
- Issues with stopping Linux VMs fixed

## 5.0.4 - 2018-08-03
### Enhancements
- Better Azure cache handling
- Update to AzureRM module 6.1
- Added support or Windows Server 2019
- Added support again for SQL Server 2008
- Added support for Windows 10 Pro on Azure
### Fixes
- Fixing a serious issue in Get-LWAzureVMConnectionInfo
- Fixed issues installing SQL Server on VMs with PowerShell 4.0
- Minor fixes
## 5.0.3 - 2018-05-24

### Enhancements
- New cmdlet Uninstall-WindowsFeature
- Telemetry is more tranparent writing evnts into the application event log
- AL as a Service is now available via REST API
- AL takes care of security settings of the host computer, added Test-LabHostRemoting
- AL looks for AllowEncryptionOracle CredSsp security setting
- AL support rolling back security changes made to the host (Undo-LabHostRemoting)

### Fixes
- Azure works again now with AzureRM module 6.1 and higher
  - Caching of operating systems was not working
- Fixed port issues with TFS on Azure
- AL now also runs on non eu-us hosts (still there is some trouble with Russian hosts)
- SCCM custom role now really works

## 5.0.1 - 2018-04-13

### Enhancements

- New SCCM custom role incl. sample script
- Added SHiPS provider
- Moved Exchange 2013 and 2016 role into custom roles and fixed some issues
- Enhanced auto-completers (works after a lab is imported)
- Support for TFS 2018

### Fixes
- Some evaluation SKUs were missing product keys
- TFS port in Azure
- Fixed bugs in Hyper-V snapshot functions
- AL will no longer try to deploy disks in parallel but waits until a job is finished
- Custom Roles now work on Azure
- Progress indicators work again

## 5.0 - 2018-04-04

### Enhancements

- TFS deployment now possible including release pipeline
- AL.Common received a new suite of cmdlets regarding TFS/VSTS management
- Linux support as domain-joined lab machines (no roles yet) capable of remoting
- Custom roles have been heavily extended
- Sample custom roles have been added
- Labs can now contain Azure Services apart from IaaS workloads
- ProGet implemented as Custom Role
- Lab telemetry added
- Voice notifications added
- Added possibility to add more external ports to Azure labs

### Fixes

- Small fixes here and there
- Issues with Windows image names fixed
- Documentation moved to markdown
- Lab XML folder moved out of "My Documents" to avoid triggering Defender
- Missing Toast messages fixed
- Display messages, timer fixed

## v4.7.2.2 - 2018-01-18

### Fixes

- AL now creates all SQL service accounts
- New image names for server 1709 taken into account
- Random spelling and formatting
- Sync-Parameter fixed so that it works with PSv2 as well
- Using Access Database Engine 2016 on a DSC Pull Server to support MDB database on Windows Server 2016
- Routing role now works on domain controllers
- Fixing some issues deploying large VM sized in Azure

### Enhancements

- Added support for Azure PaaS starting with Web Apps and App Service Plans with 12 new cmdlets and 5 new classes
- Build and release process automated
- New sample scripts
- New cmdlet Update-LabBaseImage
- New module AutomatedLab.Common added as submodule
- SQL 2017 added
- SSMS installation streamlined
- SQL Server now customizable on Azure as well
- FQDN in host file
- Extended CopiedObject.Create() to handle XmlElements, generic Lists, generic dictionaries and Nullable types
- Extended the CopiedObject.Merge method to reflect the changes made to CopiedObject.Create()
- Adding FluentFTP.dll to the tools folder
- Install-LabWindowsFeature: Added parameter IncludeManagementTools
- TFS added

## v4.5.0.0 - 2017-11-18

### Fixes

- Sync-Parameter now syncs CmdletInfo objects as well
- Automatic Checkpoints (Win10 1709) disabled
- Mount-LabIsoImage on Hyper-V (Win10 1709) fixed
- Send-ModuleToPSSession now matches three and four digit versions
- Discoverabilty of Send-ALNotification improved (which fixed issues during module import)

### Enhancements

- Failover Clustering added
  - FailoverNode: Node of a failover cluster. Role properties: ClusterName and ClusterIp
  - FailoverStorage: iSCSI target server providing iSCSI targets for each cluster. If storage is deployed, the cluster will try to automatically use a disk witness
  - Install-LabFailoverCluster: Creates the failover cluster from all machines that are FailoverNode or FailoverStorage
  - Multidomain or Workgroup clusters with OS < Server 2016: Prior to 2016 it was not possible to deploy multidomain or workgroup clusters.
  - OS < 2008 R2: Cluster cmdlets work with 2008 R2 and above
  - Duplicate cluster IPs
  - Fewer than 2 nodes per cluster
  - Sample script that deploys three clusters with varying configurations  
- SQL Sample Database Installation revised
  - Sample DBs will now be downloaded
  - Customization of download links in AutomatedLab.psd1
- SQL Setup now auto-creates domain/local accounts
  - If username and password for the SQL accounts are specified in the role properties, AL takes care of creating them
