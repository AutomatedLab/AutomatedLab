---
Module Name: AutomatedLab
Module Guid: 6ee6d36f-7914-4bf6-9e3b-c0131669e808
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLab Module
## Description
AutomatedLab (AL) enables you to setup test and lab environments on Hyper-v or Azure with multiple products or just a single VM in a very short time. There are only two requirements you need to make sure: You need the DVD ISO images and a Hyper-V host or an Azure subscription.

## Supported products

This solution supports setting up virtual machines with the following products

- Windows 7, 2008 R2, 8 / 8.1 and 2012 / 2012 R2, 10 / 2016, 2019
- SQL Server 2008, 2008R2, 2012, 2014, 2016, 2017
- Visual Studio 2012, 2013, 2015
- Team Foundation Services 2018, Azure DevOps
- Exchange 2013, Exchange 2016
- System Center Orchestrator 2012
- System Center Configuration Manager 1809
- MDT
- ProGet (Private PowerShell Gallery)
- Office 2013, 2016
- DSC Pull Server (with SQL Reporting)

## AutomatedLab Cmdlets
### [Add-LabAzureSubscription](Add-LabAzureSubscription.md)
Adds Azure subscription data to lab

### [Add-LabCertificate](Add-LabCertificate.md)


### [Add-LabVMUserRight](Add-LabVMUserRight.md)
Adds user rights on lab machines

### [Add-LabVMWareSettings](Add-LabVMWareSettings.md)
Add VMWare specific settings to the lab

### [Add-LabWacManagedNode](Add-LabWacManagedNode.md)
Add lab vms as managed systems to the lab Windows Admin Center role

### [Checkpoint-LabVM](Checkpoint-LabVM.md)
Create a VM checkpoint

### [Clear-Lab](Clear-Lab.md)
Clear lab data

### [Clear-LabCache](Clear-LabCache.md)
Clear the lab cache

### [Connect-Lab](Connect-Lab.md)
Connect two labs via VPN

### [Connect-LabVM](Connect-LabVM.md)
Connect to a lab VM

### [Copy-LabALCommon](Copy-LabALCommon.md)
Copy AutomatedLab.Common to lab machine

### [Disable-LabAutoLogon](Disable-LabAutoLogon.md)
Disable the automatic logon of a Windows account

### [Disable-LabMachineAutoShutdown](Disable-LabMachineAutoShutdown.md)
Disable Azure auto-shutdown for machines

### [Disable-LabTelemetry](Disable-LabTelemetry.md)
Disable the transmission of telemetry

### [Disable-LabVMFirewallGroup](Disable-LabVMFirewallGroup.md)
Deactivate firewall group on machine

### [Disconnect-Lab](Disconnect-Lab.md)
Disconnects two labs

### [Dismount-LabIsoImage](Dismount-LabIsoImage.md)
Dismounts an ISO

### [Enable-LabAutoLogon](Enable-LabAutoLogon.md)
Enable the automatic logon of a Windows account

### [Enable-LabAzureJitAccess](Enable-LabAzureJitAccess.md)
Enable Azure Just In Time access to lab VMs

### [Enable-LabCertificateAutoenrollment](Enable-LabCertificateAutoenrollment.md)
Enable certificate auto-enrollment

### [Enable-LabHostRemoting](Enable-LabHostRemoting.md)
Configures several local policy settings to enable lab host remoting

### [Enable-LabInternalRouting](Enable-LabInternalRouting.md)
Configure RRAS to route between lab VNets

### [Enable-LabMachineAutoShutdown](Enable-LabMachineAutoShutdown.md)
Enable Azure auto-shutdown for machines

### [Enable-LabTelemetry](Enable-LabTelemetry.md)
Enable the transmission of telemetry

### [Enable-LabVMFirewallGroup](Enable-LabVMFirewallGroup.md)
Enable firewall group on machine

### [Enable-LabVMRemoting](Enable-LabVMRemoting.md)
Enable remoting on machines

### [Enter-LabPSSession](Enter-LabPSSession.md)
Enter a PSSession

### [Export-Lab](Export-Lab.md)
Export a lab

### [Get-Lab](Get-Lab.md)
Show lab data

### [Get-LabAvailableOperatingSystem](Get-LabAvailableOperatingSystem.md)
Show available lab OS

### [Get-LabAzureAppServicePlan](Get-LabAzureAppServicePlan.md)


### [Get-LabAzureAvailableRoleSize](Get-LabAzureAvailableRoleSize.md)
Get all available Azure Compute sizes

### [Get-LabAzureAvailableSku](Get-LabAzureAvailableSku.md)
List all available operating systems on Azure

### [Get-LabAzureCertificate](Get-LabAzureCertificate.md)
Not Implemented

### [Get-LabAzureDefaultLocation](Get-LabAzureDefaultLocation.md)
Get the default Azure location

### [Get-LabAzureDefaultResourceGroup](Get-LabAzureDefaultResourceGroup.md)
Get the default resource group

### [Get-LabAzureLabSourcesContent](Get-LabAzureLabSourcesContent.md)
Get the file content of the Azure lab sources file share

### [Get-LabAzureLabSourcesStorage](Get-LabAzureLabSourcesStorage.md)
Get Azure storage data

### [Get-LabAzureLocation](Get-LabAzureLocation.md)
Get a lab location

### [Get-LabAzureResourceGroup](Get-LabAzureResourceGroup.md)
Get resource groups

### [Get-LabAzureSubscription](Get-LabAzureSubscription.md)
Get an Azure subscription

### [Get-LabAzureWebApp](Get-LabAzureWebApp.md)


### [Get-LabAzureWebAppStatus](Get-LabAzureWebAppStatus.md)


### [Get-LabBuildStep](Get-LabBuildStep.md)
Get a list of possible build steps for a TFS/Azure DevOps build pipeline

### [Get-LabCache](Get-LabCache.md)
Get the content of the lab cache

### [Get-LabCertificate](Get-LabCertificate.md)


### [Get-LabCimSession](Get-LabCimSession.md)
Cmdlet to list all or specific CIM sessions

### [Get-LabConfigurationItem](Get-LabConfigurationItem.md)
Get AutomatedLab settings

### [Get-LabHyperVAvailableMemory](Get-LabHyperVAvailableMemory.md)
Get available HyperV memory

### [Get-LabInternetFile](Get-LabInternetFile.md)
Download a file

### [Get-LabIssuingCA](Get-LabIssuingCA.md)
Get the issuing CA

### [Get-LabMachineAutoShutdown](Get-LabMachineAutoShutdown.md)
Get Azure auto shutdown config for entire lab

### [Get-LabPSSession](Get-LabPSSession.md)
Get PSSessions

### [Get-LabReleaseStep](Get-LabReleaseStep.md)
Get all possible release steps of a TFS/Azure DevOps release pipeline

### [Get-LabSoftwarePackage](Get-LabSoftwarePackage.md)
Get a software package

### [Get-LabSourcesLocation](Get-LabSourcesLocation.md)
Get lab source location

### [Get-LabSourcesLocationInternal](Get-LabSourcesLocationInternal.md)
Internal cmdlet to retrieve lab sources location

### [Get-LabSshKnownHost](Get-LabSshKnownHost.md)
Get content of SSH known host file

### [Get-LabTfsFeed](Get-LabTfsFeed.md)
List or locate Artifact feed details of an Azure DevOps/TFS instance

### [Get-LabTfsParameter](Get-LabTfsParameter.md)
Get relevant connection parameters to connect to TFS/AzDevOps

### [Get-LabTfsUri](Get-LabTfsUri.md)
Get the URI to connect to deployed TFS/AzDevOps roles

### [Get-LabVariable](Get-LabVariable.md)
Get lab variables

### [Get-LabVHDX](Get-LabVHDX.md)
Get lab disks

### [Get-LabVM](Get-LabVM.md)
Gets a lab VM object

### [Get-LabVMDotNetFrameworkVersion](Get-LabVMDotNetFrameworkVersion.md)
Get the .NET Framework version of lab VMs

### [Get-LabVMRdpFile](Get-LabVMRdpFile.md)
Get RDP connection file

### [Get-LabVMSnapshot](Get-LabVMSnapshot.md)
Get the existing checkpoints of a lab VM

### [Get-LabVMStatus](Get-LabVMStatus.md)
Gets the power state of lab machines

### [Get-LabVMUacStatus](Get-LabVMUacStatus.md)
Get the UAC status of a machine

### [Get-LabVMUptime](Get-LabVMUptime.md)
Get uptime

### [Get-LabWindowsFeature](Get-LabWindowsFeature.md)
Get Windows feature status

### [Import-Lab](Import-Lab.md)
Import a lab

### [Import-LabAzureCertificate](Import-LabAzureCertificate.md)
Not implemented

### [Initialize-LabWindowsActivation](Initialize-LabWindowsActivation.md)
Attempt to activate lab machines either through Microsoft or using KMS

### [Install-Lab](Install-Lab.md)
Starts the process of lab deployment

### [Install-LabADDSTrust](Install-LabADDSTrust.md)
Create forest trust

### [Install-LabAdfs](Install-LabAdfs.md)
Enable ADFS

### [Install-LabAdfsProxy](Install-LabAdfsProxy.md)
Create ADFS proxy

### [Install-LabAzureRequiredModule](Install-LabAzureRequiredModule.md)
Install required Azure modules for AutomatedLab

### [Install-LabAzureServices](Install-LabAzureServices.md)


### [Install-LabBuildWorker](Install-LabBuildWorker.md)
Install build worker roles

### [Install-LabConfigurationManager](Install-LabConfigurationManager.md)
Install Configuration Manager environment

### [Install-LabDcs](Install-LabDcs.md)
Install domain controllers

### [Install-LabDnsForwarder](Install-LabDnsForwarder.md)
Create DNS forwarders

### [Install-LabDscClient](Install-LabDscClient.md)
Configure DSC clients

### [Install-LabDscPullServer](Install-LabDscPullServer.md)
Install a DSC pull server

### [Install-LabDynamics](Install-LabDynamics.md)
Install lab Dynamics 365 environment

### [Install-LabFailoverCluster](Install-LabFailoverCluster.md)
Install all failover clusters

### [Install-LabFirstChildDcs](Install-LabFirstChildDcs.md)
Install the first child domain's domain controllers

### [Install-LabHyperV](Install-LabHyperV.md)
Install all Hyper-V nested hypervisors

### [Install-LabOffice2013](Install-LabOffice2013.md)
Install Microsoft Office 2013

### [Install-LabOffice2016](Install-LabOffice2016.md)
Install Microsoft Office 2016

### [Install-LabRdsCertificate](Install-LabRdsCertificate.md)
Install RDS certificates of all lab VMs

### [Install-LabRemoteDesktopServices](Install-LabRemoteDesktopServices.md)
Install RDS environment

### [Install-LabRootDcs](Install-LabRootDcs.md)
Install root domain controllers

### [Install-LabRouting](Install-LabRouting.md)
Configure RRAS

### [Install-LabScom](Install-LabScom.md)
Install SCOM environment

### [Install-LabScvmm](Install-LabScvmm.md)
Install SCVMM environment

### [Install-LabSoftwarePackage](Install-LabSoftwarePackage.md)
Install software

### [Install-LabSoftwarePackages](Install-LabSoftwarePackages.md)
Install multiple packages

### [Install-LabSqlSampleDatabases](Install-LabSqlSampleDatabases.md)
Install sample databases for the selected SQL version

### [Install-LabSqlServers](Install-LabSqlServers.md)
Install SQL servers

### [Install-LabSshKnownHost](Install-LabSshKnownHost.md)
Add all lab VMs to the SSH known hosts file

### [Install-LabTeamFoundationEnvironment](Install-LabTeamFoundationEnvironment.md)
Install all CI/CD servers in the lab

### [Install-LabWindowsAdminCenter](Install-LabWindowsAdminCenter.md)
Install WAC environment

### [Install-LabWindowsFeature](Install-LabWindowsFeature.md)
Install a Windows feature

### [Invoke-LabCommand](Invoke-LabCommand.md)
Invoke command on a lab vm

### [Invoke-LabDscConfiguration](Invoke-LabDscConfiguration.md)
Invoke a DSC configuration on one or more nodes

### [Join-LabVMDomain](Join-LabVMDomain.md)
Join a VM to a domain

### [Mount-LabIsoImage](Mount-LabIsoImage.md)
Mount an ISO

### [New-LabADSubnet](New-LabADSubnet.md)
Create new AD subnet

### [New-LabAzureAppServicePlan](New-LabAzureAppServicePlan.md)


### [New-LabAzureLabSourcesStorage](New-LabAzureLabSourcesStorage.md)
Create Azure lab source storage

### [New-LabAzureRmResourceGroup](New-LabAzureRmResourceGroup.md)
Wrapper to create a new resource group and include it in the lab metadata

### [New-LabAzureWebApp](New-LabAzureWebApp.md)


### [New-LabBaseImages](New-LabBaseImages.md)
Function to create base images for all OSses used in the current lab

### [New-LabCATemplate](New-LabCATemplate.md)
Create CA template

### [New-LabCimSession](New-LabCimSession.md)
Create new lab CIM sessions

### [New-LabPSSession](New-LabPSSession.md)
Create PowerShell sessions

### [New-LabReleasePipeline](New-LabReleasePipeline.md)
Create a new release pipeline

### [New-LabSourcesFolder](New-LabSourcesFolder.md)
Create and populate a new labsources folder

### [New-LabTfsFeed](New-LabTfsFeed.md)
Create new Artifact Feed on lab TFS/Azure DevOps infrastructure

### [New-LabVHDX](New-LabVHDX.md)
Create new VHDX

### [New-LabVM](New-LabVM.md)
Create a new virtual machine

### [Open-LabTfsSite](Open-LabTfsSite.md)
Open the CI/CD servers home page

### [Register-LabArgumentCompleters](Register-LabArgumentCompleters.md)
Register the necessary argument completers for AutomatedLab

### [Remove-LabDeploymentFiles](Remove-LabDeploymentFiles.md)
Remove deployment data

### [Remove-Lab](Remove-Lab.md)
Remove the lab

### [Remove-LabAzureLabSourcesStorage](Remove-LabAzureLabSourcesStorage.md)
Removes the lab sources

### [Remove-LabAzureResourceGroup](Remove-LabAzureResourceGroup.md)
Remove a resource group

### [Remove-LabCimSession](Remove-LabCimSession.md)
Remove open CIM sessions to lab VMs

### [Remove-LabDeploymentFiles](Remove-LabDeploymentFiles.md)
Remove deployment data

### [Remove-LabDscLocalConfigurationManagerConfiguration](Remove-LabDscLocalConfigurationManagerConfiguration.md)
Reset the LCM configuration of a lab VM

### [Remove-LabPSSession](Remove-LabPSSession.md)
Remove sessions

### [Remove-LabVariable](Remove-LabVariable.md)
Remove AutomatedLab variables

### [Remove-LabVM](Remove-LabVM.md)
Remove a VM

### [Remove-LabVMSnapshot](Remove-LabVMSnapshot.md)
Remove a snapshot

### [Request-LabAzureJitAccess](Request-LabAzureJitAccess.md)
Request JIT access for a given time span

### [Request-LabCertificate](Request-LabCertificate.md)
Request a certificate

### [Reset-AutomatedLab](Reset-AutomatedLab.md)
Reset the lab

### [Restart-LabVM](Restart-LabVM.md)
Restart a machine

### [Restart-ServiceResilient](Restart-ServiceResilient.md)
Restart a service

### [Restore-LabConnection](Restore-LabConnection.md)
Restore the lab connection

### [Restore-LabVMSnapshot](Restore-LabVMSnapshot.md)
Restore a snapshot

### [Save-LabVM](Save-LabVM.md)
Save a VM

### [Set-LabAzureDefaultLocation](Set-LabAzureDefaultLocation.md)
Set Azure location

### [Set-LabAzureWebAppContent](Set-LabAzureWebAppContent.md)


### [Set-LabDefaultOperatingSystem](Set-LabDefaultOperatingSystem.md)
Set default OS

### [Set-LabDefaultVirtualizationEngine](Set-LabDefaultVirtualizationEngine.md)
Set default virtualization engine

### [Set-LabDscLocalConfigurationManagerConfiguration](Set-LabDscLocalConfigurationManagerConfiguration.md)
Set LCM settings for a node

### [Set-LabGlobalNamePrefix](Set-LabGlobalNamePrefix.md)
Set a machine prefix

### [Set-LabInstallationCredential](Set-LabInstallationCredential.md)
Set the installation credential

### [Set-LabVMUacStatus](Set-LabVMUacStatus.md)
Set the UAC

### [Show-LabDeploymentSummary](Show-LabDeploymentSummary.md)
Show installation time

### [Start-LabAzureWebApp](Start-LabAzureWebApp.md)


### [Start-LabVM](Start-LabVM.md)
Start a machine

### [Stop-LabAzureWebApp](Stop-LabAzureWebApp.md)


### [Stop-LabVM](Stop-LabVM.md)
Stop a machine

### [Sync-LabActiveDirectory](Sync-LabActiveDirectory.md)
Start AD replication

### [Sync-LabAzureLabSources](Sync-LabAzureLabSources.md)
Sync local lab sources to Azure

### [Test-FileHashes](Test-FileHashes.md)
Tests a file hash

### [Test-FileList](Test-FileList.md)
Test a file list

### [Test-FolderExist](Test-FolderExist.md)
Test-Path

### [Test-FolderNotExist](Test-FolderNotExist.md)
Test-Path

### [Test-LabADReady](Test-LabADReady.md)
Test if lab ADWS are ready for scripting

### [Test-LabAutoLogon](Test-LabAutoLogon.md)
Test if the autologon settings are correct

### [Test-LabAzureLabSourcesStorage](Test-LabAzureLabSourcesStorage.md)
Test if the Azure labsources file share exists

### [Test-LabAzureModuleAvailability](Test-LabAzureModuleAvailability.md)
Test if Azure modules are installed and have the required version

### [Test-LabCATemplate](Test-LabCATemplate.md)
Test CA template existence

### [Test-LabHostConnected](Test-LabHostConnected.md)
Test if the lab host is connected

### [Test-LabHostRemoting](Test-LabHostRemoting.md)
Check if remoting settings on lab host are correct

### [Test-LabMachineInternetConnectivity](Test-LabMachineInternetConnectivity.md)
Check internet connection

### [Test-LabPathIsOnLabAzureLabSourcesStorage](Test-LabPathIsOnLabAzureLabSourcesStorage.md)
Tests if a path is on Azure

### [Test-LabTfsEnvironment](Test-LabTfsEnvironment.md)
Test lab TFS/Azure DevOps deployment

### [Unblock-LabSources](Unblock-LabSources.md)
Unblock lab sources

### [Undo-LabHostRemoting](Undo-LabHostRemoting.md)
Reset the local policy values to their defaults

### [Uninstall-LabRdsCertificate](Uninstall-LabRdsCertificate.md)
Remove RDS certificates of all lab VMs from cert store

### [UnInstall-LabSshKnownHost](UnInstall-LabSshKnownHost.md)
Remove lab VMs from SSH known hosts file

### [Uninstall-LabWindowsFeature](Uninstall-LabWindowsFeature.md)
Uninstalls a Windowsfeature of one or more Lab Machines

### [Update-LabAzureSettings](Update-LabAzureSettings.md)
Update Azure settings

### [Update-LabBaseImage](Update-LabBaseImage.md)
Update a base image with OS updates

### [Update-LabIsoImage](Update-LabIsoImage.md)
Update an ISO

### [Update-LabSysinternalsTools](Update-LabSysinternalsTools.md)
Download new Sysinternals Suite

### [Wait-LabADReady](Wait-LabADReady.md)
Wait for the lab AD

### [Wait-LabVM](Wait-LabVM.md)
Wait for VM

### [Wait-LabVMRestart](Wait-LabVMRestart.md)
Wait for machine restart

### [Wait-LabVMShutdown](Wait-LabVMShutdown.md)
Wait for machine shutdown

