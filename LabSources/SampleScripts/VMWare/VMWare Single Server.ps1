<# Prerequisites :
    - VMware environment with vCenter server
    - ResourcePool 'Resources'
    - A VM folder named Templates
    - In that folder, a powered down VM named 'AL_WindowsServer2012R2DataCenter', fully installed with said OS, and VMware tools installed.\
    - A snapshot of the VM above (this is to be used as master to the linked clones)
#>

#Requires -Modules @{ ModuleName="VMware.VimAutomation.Core" ; ModuleVersion="6.5.1.0" }
#Requires -RunAsAdministrator

# Redirect $env:PSmodulepath to develop AutomatedLab modules
# $path = "E:\i386\Users\torsten\GitHub\AutomatedLab"
# $env:PSModulePath += ";$path"

# Save a credential for VMware access
$cred = (Get-Credential torsten@vsphere.local)

# Import VMware modules to current session
# Get-Module -ListAvailable vmware* | import-module

$VerbosePreference = "Continue"

New-LabDefinition -Name VMwareLab -DefaultVirtualizationEngine VMware

Add-LabVMwareSettings -DataCenterName "Datacenter" -DataStoreName datastore1 -VCenterServerName vcenter -Credential $cred -ResourcePoolName Resources

Add-LabVirtualNetworkDefinition -Name AutomatedLabNetwork -VirtualizationEngine VMware -AddressSpace 192.168.10.0

Add-LabMachineDefinition -Name VMwareLab-Test1 -Memory 4GB -Processors 2 -OS 'Windows Server 2012 R2 Datacenter (Server with a GUI)' -Roles WebServer

#Import-Lab VMwareLab

Install-Lab
