---
Module Name: AutomatedLabWorker
Module Guid: 3addac35-cd7a-4bd2-82f5-ab9c83a48246
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.0.0
Locale: en-US
---

# AutomatedLabWorker Module
## Description
AutomatedLabWorker is a helper module intended to be used within AutomatedLab. There is usually no need to execute the cmdlets unless you are contributing to AutomatedLab.

## AutomatedLabWorker Cmdlets
### [Add-LWAzureLoadBalancedPort](Add-LWAzureLoadBalancedPort.md)
Add a new port to the Azure load balancer

### [Add-LWVMVHDX](Add-LWVMVHDX.md)
Attach a VHDX file to a VM

### [Checkpoint-LWAzureVM](Checkpoint-LWAzureVM.md)
Create a snapshot of an Azure VM

### [Checkpoint-LWHypervVM](Checkpoint-LWHypervVM.md)
Create a checkpoint of a Hyper-V VM

### [Connect-LWAzureLabSourcesDrive](Connect-LWAzureLabSourcesDrive.md)
Connect the Azure File Share 'LabSources' in a session

### [Disable-LWAzureAutoShutdown](Disable-LWAzureAutoShutdown.md)
Internal worker to disable Azure Auto Shutdown

### [Dismount-LWAzureIsoImage](Dismount-LWAzureIsoImage.md)
Unmount an ISO image on an Azure VM

### [Dismount-LWIsoImage](Dismount-LWIsoImage.md)
Unmount all ISOs from a Hyper-V VM

### [Enable-LWAzureAutoShutdown](Enable-LWAzureAutoShutdown.md)
Internal worker to enable Azure Auto Shutdown

### [Enable-LWAzureVMRemoting](Enable-LWAzureVMRemoting.md)
Enable Windows Remote Management on an Azure VM

### [Enable-LWAzureWinRm](Enable-LWAzureWinRm.md)
Enable CredSSP and WinRM

### [Enable-LWHypervVMRemoting](Enable-LWHypervVMRemoting.md)
Enable CredSSP on a Hyper-V VM

### [Enable-LWVMWareVMRemoting](Enable-LWVMWareVMRemoting.md)
Enable CredSSP on a VMWare VM

### [Get-LabAzureLoadBalancedPort](Get-LabAzureLoadBalancedPort.md)
Return the custom load-balanced ports of an Azure VM

### [Get-LWAzureAutoShutdown](Get-LWAzureAutoShutdown.md)
Internal worker to list Azure Auto Shutdown

### [Get-LWAzureLoadBalancedPort](Get-LWAzureLoadBalancedPort.md)
List ports on the Azure load balancer

### [Get-LWAzureNetworkSwitch](Get-LWAzureNetworkSwitch.md)
Get the Azure Virtual Network associated with a lab network

### [Get-LWAzureSku](Get-LWAzureSku.md)
Internal worker to list Azure SKUs

### [Get-LWAzureVm](Get-LWAzureVm.md)
Get Azure VMs in the lab resource group

### [Get-LWAzureVMConnectionInfo](Get-LWAzureVMConnectionInfo.md)
Return the connection details of Azure VMs

### [Get-LWAzureVmSize](Get-LWAzureVmSize.md)
Return configured size of lab VM

### [Get-LWAzureVmSnapshot](Get-LWAzureVmSnapshot.md)
List an Azure snapshot

### [Get-LWAzureVMStatus](Get-LWAzureVMStatus.md)
Returns the power state of a lab's Azure VMs

### [Get-LWAzureWindowsFeature](Get-LWAzureWindowsFeature.md)
List installed Windows features on an Azure VM

### [Get-LWHypervVM](Get-LWHypervVM.md)
Get all VMs running on a Hyper-V

### [Get-LWHypervVMDescription](Get-LWHypervVMDescription.md)
Return the serialized notes field of a Hyper-V VM

### [Get-LWHypervVMSnapshot](Get-LWHypervVMSnapshot.md)
Find snapshots of Hyper-V VMs

### [Get-LWHypervVMStatus](Get-LWHypervVMStatus.md)
Get the power state of a Hyper-V VM

### [Get-LWHypervWindowsFeature](Get-LWHypervWindowsFeature.md)
Get Windows features from a Hyper-V VM

### [Get-LWVMWareNetworkSwitch](Get-LWVMWareNetworkSwitch.md)
Return a VMWare network switch for a lab network

### [Get-LWVMWareVMStatus](Get-LWVMWareVMStatus.md)
Get the power state of a VMWare VM

### [Initialize-LWAzureVM](Initialize-LWAzureVM.md)
Initialize new Azure VM

### [Install-LWAzureWindowsFeature](Install-LWAzureWindowsFeature.md)
Enable a Windows feature on an Azure VM

### [Install-LWHypervWindowsFeature](Install-LWHypervWindowsFeature.md)
Enable a Windows feature on a Hyper-V VM

### [Install-LWLabCAServers](Install-LWLabCAServers.md)
{{ Fill in the Synopsis }}

### [Install-LWLabCAServers2008](Install-LWLabCAServers2008.md)
{{ Fill in the Synopsis }}

### [Invoke-LWCommand](Invoke-LWCommand.md)
Cmdlet executed by Invoke-LabCommand

### [Mount-LWAzureIsoImage](Mount-LWAzureIsoImage.md)
Mount an ISO image on an Azure VM

### [Mount-LWIsoImage](Mount-LWIsoImage.md)
Mounts an ISO image on a Hyper-V VM

### [New-LabAzureResourceGroupDeployment](New-LabAzureResourceGroupDeployment.md)
Deploy the lab definition as an Azure resource group

### [New-LWHypervNetworkSwitch](New-LWHypervNetworkSwitch.md)
Create a new Hyper-V switch

### [New-LWHypervVM](New-LWHypervVM.md)
Create a new Hyper-V VM

### [New-LWHypervVmConnectSettingsFile](New-LWHypervVmConnectSettingsFile.md)
Creates a VMConnect config file for the given Hyper-V machine.

### [New-LWReferenceVHDX](New-LWReferenceVHDX.md)
Create a reference disk from an OS image

### [New-LWVHDX](New-LWVHDX.md)
Create a new virtual disk

### [New-LWVMWareVM](New-LWVMWareVM.md)
Create a new VMWare VM

### [Remove-LWAzureRecoveryServicesVault](Remove-LWAzureRecoveryServicesVault.md)
Remove recovery services vault in lab resource group

### [Remove-LWAzureVM](Remove-LWAzureVM.md)
Remove an Azure VM

### [Remove-LWAzureVmSnapshot](Remove-LWAzureVmSnapshot.md)
Remove an Azure VM snapshot

### [Remove-LWHypervVM](Remove-LWHypervVM.md)
Remove a Hyper-V VM

### [Remove-LWHypervVmConnectSettingsFile](Remove-LWHypervVmConnectSettingsFile.md)
Removes the VMConnect config file to the given Hyper-V VM.

### [Remove-LWHypervVMSnapshot](Remove-LWHypervVMSnapshot.md)
Remove Hyper-V checkpoints

### [Remove-LWNetworkSwitch](Remove-LWNetworkSwitch.md)
Remove a Hyper-V network switch

### [Remove-LWVHDX](Remove-LWVHDX.md)
Remove a VHDX file

### [Remove-LWVMWareVM](Remove-LWVMWareVM.md)
Remove a VMWare virtual machine

### [Repair-LWHypervNetworkConfig](Repair-LWHypervNetworkConfig.md)
Reorder and rename Hyper-V VM network adapters

### [Restore-LWAzureVmSnapshot](Restore-LWAzureVmSnapshot.md)
Restore the snapshot of an Azure VM

### [Restore-LWHypervVMSnapshot](Restore-LWHypervVMSnapshot.md)
Restore a Hyper-V VM checkpoint

### [Save-LWHypervVM](Save-LWHypervVM.md)
Save the state of a Hyper-V VM

### [Save-LWVMWareVM](Save-LWVMWareVM.md)
Save the state of a VMWare VM

### [Set-LWAzureDnsServer](Set-LWAzureDnsServer.md)
Set the DNS servers of an Azure virtual network

### [Set-LWHypervVMDescription](Set-LWHypervVMDescription.md)
Set the Notes field of a Hyper-V VM

### [Start-LWAzureVM](Start-LWAzureVM.md)
Start Azure VMs

### [Start-LWHypervVM](Start-LWHypervVM.md)
Start a Hyper-V VM

### [Start-LWVMWareVM](Start-LWVMWareVM.md)
Start a VMWare VM

### [Stop-LWAzureVM](Stop-LWAzureVM.md)
Stop an Azure VM

### [Stop-LWHypervVM](Stop-LWHypervVM.md)
Stop a Hyper-V VM

### [Stop-LWVMWareVM](Stop-LWVMWareVM.md)
Stop a VMWare VM

### [Test-IpInSameSameNetwork](Test-IpInSameSameNetwork.md)
Test if an IP address is in the same network as another address

### [Uninstall-LWAzureWindowsFeature](Uninstall-LWAzureWindowsFeature.md)
Disable a Windows feature on an Azure VM

### [Uninstall-LWHypervWindowsFeature](Uninstall-LWHypervWindowsFeature.md)
Disable a Windows feature on a Hyper-V VM

### [Wait-LWAzureRestartVM](Wait-LWAzureRestartVM.md)
Wait for the restart of an Azure VM

### [Wait-LWHypervVMRestart](Wait-LWHypervVMRestart.md)
Wait for the restart of a Hyper-V VM

### [Wait-LWLabJob](Wait-LWLabJob.md)
Wait for a job

### [Wait-LWVMWareRestartVM](Wait-LWVMWareRestartVM.md)
Wait for the restart of a VMWare VM

