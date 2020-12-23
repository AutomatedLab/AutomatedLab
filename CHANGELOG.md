# Changelog

## Unreleased
<!-- SCROLL DOWN TO ENHANCEMENTS AND BUG FIXES PLEASE -->

### Enhancements

### Fixes

- Fix unnessary UEFI dependency of Update-LabIsoImage
- Fixed that only the first additional 10 disks were initialized
- Fixed regex, considering drives with underscores and hyphens in the name now

## 5.30.0 (2020-12-15)

### Enhancements

- Added SCVMM Role to deploy SCVMM 2016 and 2019
- 'FailoverStorage' is available as a separate install option
- Speed of Add-LabIsoImageDefinition on Azure increased by adding Path parameter
- Added two new validators: DuplicateAddressAssigned, NonExistingDnsServerAssigned

### Fixes

- Aligned the name of the 'DscMofEncryption' template with its display name
- Fixed issue with Install-LabSoftwarePackage not working for Azure VMs outside of $LabSources (Issue #989)
- Installing RDS certificates and calling the Pester tests only if $performAll or explicitly defined. Before Install-Lab 
  threw errors in case only some parts of the lab deployment should be done.
- Remove-LabVm now removes associated resources on Azure (Issue #998 and #997)
- New-LabSourcesFolder now actually copies dev branch.
- Improved error handling in Azure ARM deployment for disks.
- Added error handling when trying to restore snapshots in Azure that don't exist.
- Fixes an issue with RegEx resulting in not initialize all additional disks (Issue #1006).
- Fixes issues with Update-LabIsoImage not working
- Fixes issue with DSC Pull Server role validation so that SQL2016 and newer is supported
- Fixes an issue where SQL2019 sample databases were not installed correctly (#992)
- Old types in Add / Get-Certificate2 threw many errors, fixed that.
- Fixed processor count on multi-processor systems.
- Fixed NIC to Subnet assignment on Azure
- Fixed issue where if AutomatedLab.LabSourcesLocation is configured with an empty string, testing for it was wrong. (#1035)
- Fixed issue where Windows Admin Center would be installed when not specified (#1029)
- Fixed an issue where SQLNcli would not be installed for SCCM custom roles (#1031)
- Fixed a visual issue during SQL deployment on Azure (New-Item is called on $labsources)

## 5.22.0 - 2020-07-10

### Enhancements

- Parameter ReferenceDiskSizeInGB now works by created additional reference disks with different sizes (Fixes #862)
- AutomatedLabTest updated to use Pester V5
- Build Agent role can now get Capabilities through its role definition
  - New key Capabilities which contains a hashtable (within the realms of what is possible with Azure DevOps)
- New cmdlet Get-LabTfsParameter to retrieve standard parameter dictionary
  which can be used with our TFS cmdlets. Reduced a lot of duplicated code.
- Connect-LabVM uses full screen mode by default
- Fixed #561
- Added CM-2002 CustomRole
  - Uses Configuration Manager 2002 baseline media
  - Supports Technical Preview (including updating to the latest release)
  - -ExternalVMSwitchName accepts the "Default Switch"
- Updated CM-1902 CustomRole
  - -ExternalVMSwitchName accepts the "Default Switch"
  - Max -CMVersion is now 1910 (use CM-2002 CustomRole if you want newer), formatting
- Transfer of ALCommon library takes place in Wait-LabVM or Initialize-LWAzureVM now to have the lib on all lab VMs.
- Custom Roles can now have any parameter type they would like, fixing #925
- Install-Lab imports the VMs RDP certificates and Remove-Lab removes them to enable seamless Connect-LabVm
- Relaxed Azure password policy as special characters are not mandatory.
- Windows Admin Center implemented as proper Role to enable SkipDeployment parameter
- Including name of used function in telemetry, for all functions using Write-LogFunctionEntry
- ResourceName parameter of Add-LabMachineDefinition now actually supported. Fixes #23
  - No interaction is done in AL using the resource name. This is only for the purpose of
    deploying the same lab on the same host with different resource names (VM names, switch names)
- Enabling configuration of allowed inbound IP addresses for Azure load balancer
  
### Bug Fixes
- Get-LabInternetFile did not work on Azure when the Uri did not contain a file name like 'https://go.microsoft.com/fwlink/?Linkid=85215'.
- Decreased runtime of installation on Azure by disabling the Azure LabSources check in Copy-LabAlCommon
- Build Agent role on Azure can now again connect to its server (Fixes #938)
- Fixed Install-LabRdsCertificate which did not work with 2012 R2 lab VMs
- LabSources folder is now supported in SD cards or memory sticks (Fixes #946)
- Ensure drive letter gets assigned when mounting an image (Fixes #874)
- Fixed Azure error handling
- Added compatibility with CentOS 8 (partially fixes #967)

## 5.21.0 - 2020-05-26

### Enhancements

- Added NuGet custom role that uses open source NuGet server package
- AL now deploys ARM templates instead of individual resources
- Compatibility with Az module 4.1.0. The minimum version of Az is now 4.1.0
- LabSources location can now be configured

### Bug Fixes

- Fixed module import loop (Fixes #869)
- Release tagging updated
- Fixed an issue where Azure labs would prompt the user even when in a non-interactive environment
- 'Enable-LabAutoLogon' does no longer use CredSSP as this authentication protocol is not enabled at that early stage (fixes #880)
- DelayBetweenComputers works now if defined and if not is calculated based on the umber of machines
- Fixing an 'Cannot index into a null array' error when answering the very first telemetry question with 'Ask later' (fixes #884)
- Several CM-1902 CustomRole fixes/improvements: Formatting and grammar, make -NoInteretAccess work, download SQL ISO directly rather than via downloader application, removed hardcoded VM specs for ConfigMgr VM, data and SQL VHDX names on host's disk match hostname of ConfigMgr VM.
- 'Get-LabIssuingCA' does no longer throw but returns $null if there is no certificate authority present in the lab.
- Updated some paths to work cross-platform
  - i.e. Join-Path fails when the drive does not exist, so all calls to e.g. Send-File with a destination like C: would
    fail on Linux, even though the target would always be a Windows machine. Replaced those paths with forward slash
    which defaults to the system root on Windows and can be resolved cross-platform
- Fixed an issue where the CimAssociatedInstances for the network adapter could not be reliably retrieved with the current insider builds.
- Fixed #890.
- Fixed and improved 'Test-LabMachineInternetConnectivity'
- 'Dismount-LabIsoImage' on Azure did never really work, no fixed and behavior is now aligned to the Hyper-V behavior.
- 'Mount-LWAzureIsoImage' is no longer copying the image to a local drive but mounts it from the network drive.
- Integrated web server deployment into NugetServer custom role (Fixes #881)
- Fixed SQL Server version in '06 SQL Server and client, domain joined.ps1'.
- ARM Template Deployment now deploys outgoing NAT as well, re-enabling VM internet access...
- Re-enabled BGInfo

## 5.20.0 - 2020-04-20

### Enhancements

- AL can now use SSDs and UltraSSD skus (Fixes #763)
- Agent Pool assignment on build worker now possible
- Build workers can now be added without adding an AzDevOps lab machine
- AL is now packaged as deb and rpm packages (kindly be reminded that this is still a beta feature :smirk: )

### Bug Fixes

- TFS Build Worker Role was undeployable when parameter TfsServer was used (#852).
- Resolves a terminating error thrown by ConvertFrom-StringData if strings contained a non-escaped backslash.
- Fixed an issue installing .net 4.8 in SQL server issue.
- Fixed #846 not being able to deploy Windows 10 1909.
- 'doNotSkipNonNonEnglishIso' did not work as there as a scoping issue with the variable (#860).
- Fixed an issue with the new dependencies and moved them to offline installer.

## 5.19.0 - 2020-04-03

### Enhancements
- SQL setup now does not override custom configuration file any longer when no other parameters are specified.
- Add-LabMachineDefinition now assumes the most recent OS as a default if no system is specified.
- Added System Center Configuration Manager 1902 custom role - Thank you @codaamok !
- Lab Sources folder is automatically updated now, too.
  - Will reduce issues with missing dependencies on post install activities that get renamed without an info...
- Added support for multiple 'TfsBuildWorkers' on one machine.
- Added option for specifying own SQL ISO for CM1902 example script for CM1902 custom role. If parameter is omitted it will auto download eval edition from Microsoft.
- Change forwarders to AD integrated.
- Added additional validator for DSC Pull Server Setup to validate if a CA is present.
- File Server Role: Installed detection.
- Removed parameter 'Path' from 'New-LabDefinition' and help
- Removed parameter 'NoAzurePublishSettingsFile' from 'New-LabDefinition' and help
- Linux is now a supported host operating system for Azure-based lab environments
- CIM Cmdlets Get/New/Remove-LabCimSession
- Lab with Domain Join added (Fixes #194)

### Bug Fixes
- Fixes hardcode reference to a SQL configuration file with the path supplied in SQL role's properties `ConfigurationFile` - Thank you @codaamok !
- Fixes timing issues with ADDS on Azure by skipping the wait period for guest reboots on Azure.
- Rewritten some of the logic in Get-LabInternetFile.
  - Improves performance of Get-LabInternetFile.
  - Makes it working with more types of URLs.
  - Fixed a newly introduced bug.
- Replaced 'Get-Lab' call with lab definition data already available. 'Get-Lab' does not work as the deployment hasn't yet started.
- Fixed a bug that prevented the call of 'Stop-LabVM2'.
- Fixed a type (= != -eq).
- Fixed domain join performance issue. Joining to a domain took at least 15 minutes.
- Removed parameter 'Path' from 'New-LabDefinition' and help.
- Removed parameter 'NoAzurePublishSettingsFile' from 'New-LabDefinition' and help.
- 'Test-LabPathIsOnLabAzureLabSourcesStorage' is only called if lab's DefaultVirtualizationEngine is Azure.
- Fixed #806, Invoke-Command : Specified RemoteRunspaceInfo objects have duplicates.
- Fixed a casting issue in 'UnknownRoleProperties' validator.
- Fixed #814 (case sensitivity).
- Fixed #821 by adding 'AutomatedLab.Recipe' and 'AutomatedLab.Ships' to the RequiredModules.
- Adding missing files to VS solution and installer.
- Fixed domain join performance issue. Joining to a domain took at least 15 minutes.
- Rewritten some of the logic in Get-LabInternetFile.
  - Improves performance of Get-LabInternetFile.
  - Makes it working with more types of URLs.
  - Fixed a newly introduced bug.
- Fixed an issue with newer OpenSuSE ISOs not having a .content file
- Fixed an issue where Wait-LabVm timed out on an existing domain controller

## 5.17.0 - 2020-01-08

### Enhancements

- Happy New Year.
- Sample scripts updated
  - to at least Server 2016
  - Links to WMF
- Mac Address Spoofing enabled on Hyper-V
- Azure Auto-Shutdown implemented
- Added parameter to include the removal of external switches
- Implemented SQL Server 2019, thanks @SQLDBAWithABeard !
- Implemented SharePoint 2019, updated 2013 and 2016
- MDT custom role updated
- Added TFS/Azure DevOps artifact feeds (nuget feeds)

### Bug fixes

- Fixed issue with Write-PSFMessage, thanks @awickham10 !
- Fixed typos, thanks @wikijm !
- Fixed issue with LabAutoLogon, thanks @astavitsky !
- Links fixed, thanks @adilio !
- Fixed Azure subscription handling when multiple subscriptions with the same name existed
- Fixed issue with Exchange custom roles
- Fixed unhandled exceptions in case the Hyper-V VM notes are not readable as XML
- Improved error handling if no Az module is available
- Fixed issues in 'Reset-LabAdPassword' and 'Enable-LabAutoLogon'

## 5.16.0 - 2019-09-29

### Enhancements

- Changed user interaction when asking user for telemetry permission
- Disabling .net optimization scheduled tasks on all 2012R2+ machines
- Updated Sql2017ManagementStudio link to version 18.2

### Bug fixes
- Azure module test method updated to actually locate the Az module (Fixed #671)

## 5.15.0 - 2019-09-20

### Enhancements

- Added support for Exchange 2019 including sample scripts (Thanks to @damorris)
- Added support for Office 2019 including sample scripts (Thanks to @damorris)
- Included SSRS 2017 in SQL Setup
- Updated a couple of download links
- Calling 'Test-LabPathIsOnLabAzureLabSourcesStorage' only if the currently, improves performance
- Improved the deployment of the ProGet custom role
- Removing parameter 'ProductKey' as it is not used and not working
- Performance improvements

### Bug fixes

- Fixed #646 Restore-LabVMSnapshot throws errors
- Fixed #709 Bootloader did not load an operating system

## 5.13.0 - 2019-06-27

### Bug fixes
- Copy-LabFileItem in Install-LabSoftwarePackage introduced new issue

## 5.13.0 - 2019-06-27

### Bug fixes
- Software installation in Azure failing
- Installer needs to install PSFramework
- Set module version of AutomatedLab.Common in manifest to ensure recent version when
downloaded through PSGallery
- Removed dependency of PSFileTransfer to PSFramework, as cmdlets were used in remote sessions

## 5.11.0 - 2019-06-26

### Bug fixes
- DNS forwarder on Azure DC will not be reset any longer (thanks @dmi3mis)
- Certificate issues fixed
- Azure module version increase
- Set-LabInstallationCredential now checks Azure password rules
- Old exchange installation fixed
- Software installation on lab clients with PS < 5 fails
- Fixing error messages during lab deployment when CustomRoles folder is missing (but unused)

### Enhancements
- Deployment test added to TFS deployment
- Help updated to use ReadTheDocs.io
- .NET Core compatibility enabled
- Adopted PSFramework in favor of datum (Thanks @friedrichweinmann for PSFramwork!)
- Aliases replaced
- AutomatedLabNotifications is able to use Microsoft.Speech (Voice output)

## 5.10.0 - 2019-05-15

### Bug fixes

- Fixed issue with Azure resource groups occasionally not getting removed
- Azure port mapping for TFS, DSC Pull, ... improved
- Bug with DSC SQL Database Creation for Pull Server fixed
- Get-LabInternetFile on Azure fixed
- Offline Hyper-V environments now don't complain about Azure-related things any more

### Enhancements

- Hyper-V role added for lab machines
- Copy-LabFileItem now also copies hidden files
- Using Az 2.0 now
- Windows Admin Center implemented on Azure as well

## 5.9.0 - 2019-03-25

### Enhancements

- Implemented new cmdlet Get-LabVmSnapshot (fixes #611)
- Added Enable and Disable-LabAutoLogon
- AGPM Sample Script updated to ensure compatibility with Azure
- Added cmdlet Test-LabHostConnected to test internet connectivity before trying things on Azure
- Server 2019 added to list of Azure images
- New-LabReleasePipeline now publishes all branches to lab TFS
- Improved handling for Checkpoint-/Restore-LabVm

### Bug fixes

- Performance issues lessened
- Sample scripts corrected (Thank you @waiholiu !)
- Random Lab XML corruptions fixed

## 5.7.0 - 2019-02-16

### Enhancements

- New module "AutomatedLab.Recipe" to make AL available to less technically-inclined audience
- New function Get-LabCache
- Support for custom DNS label on Azure

## 5.6.0 - 2019-02-08

### Bug fixes

- MSI installer produced three-digit modules in four digit directories

### Enhancements

- AppVeyor build process updated to make versioning prettier
- TFS build worker setup updated to use SChannel

## 5.5.* - 2019-01-30

### Enhancements

- Update to Az module 1.0
- Machines can now be skipped during deployment
- Teamed switch interfaces are now supported (Thanks @GlennJC !)
- Settings moved from module manifest to global and user-defined PSD1 files [See here](https://github.com/AutomatedLab/AutomatedLab/wiki/Customizing-deployment-settings)
  - New cmdlet: Get-LabConfigurationItem to retrieve a setting
- Snapshots of Azure VMs implemented
- New product keys added, product keys can now be defined in XML files
- VLANs are now  (Thanks @GlennJC !)
- Exchange 2016 updated to CU11 (Thanks @dmi3mis !)
- Exchange 2013 updated to support CU21, several other additions  (Thanks @GlennJC !)
- MDT custom role updated to support ADK 1809 (Thanks @GlennJC !)
- Get-LabInternetFile now allows specifying a file name
- Timeout for Wait-LWLabJob increased (Thanks @dmi3mis !)
- Copy-LabFileItem now supports -PassThru
- Auto-sync of lab sources to Azure implemented, users will get asked once to use this feature

### Bug fixes

- Azure: Multiple NICs and multiple disks now work again
- Install user now part of SQL admin groups
- Fixed issue with Exchange parameters
- Send-ALNotification does not throw any more when sending a Toast
- Broken ODT link fixed (Thanks @dmi3mis !)
- Validators MandatoryRoleProperties' and 'UnknownRoleProperties' fixed

## 5.1.0 - 2018-11-26

### Enhancements

- Additional parameters for Add-LabDiskDefinition: AllocationUnitSize, DriveLetter, Label
- Additional role parameters for AD: DatabasePath, LogPath, SysvolPath, DsmPassword
- SQL setup: Accounts in SQL setup ini are now auto-created as well
- BitLocker write protection check where new volumes would be read-only due to a possible policy/registry setting (Thanks @sk82jack !)
- General code cleanup (Thanks @KevinMarquette !)
- Configurable MAC address space

### Bug fixes

- Issue with whitespace in CACommonName fixed
- Issue with improper retrieval of variables during CA deployment fixed
- Issue with Windows 1809 and -DiskImage cmdlets producing unwanted output fixed
- Fixed SQL Setup (2016+) by preinstalling C++ redist

## 5.0.4 - 2018-09-28

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
