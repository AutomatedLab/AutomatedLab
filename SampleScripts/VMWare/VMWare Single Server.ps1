<# Prerequisites :
    - VMware environment with vCenter server
    - ResourcePool 'Test'
    - A VM folder named Templates
    - In that folder, a powered down VM named 'AL_WindowsServer2012R2DataCenter', fully installed with said OS, and VMware tools installed.\
    - A snapshot of the VM above (this is to be used as master to the linked clones)
#>

# Redirect $env:PSmodulepath to develop AutomatedLab modules
$path = "C:\Users\Jos\Documents\GitHub\AutomatedLab"
$env:PSModulePath += ";$path"

# Save a credential for VMware access
$cred = (get-credential administrator@vsphere.local)

# Import VMware modules to current session
get-module -ListAvailable vmware* | import-module

# unload Hyper-V
get-module hyper-v | Remove-Module

New-LabDefinition -Name VMWareLab -VmPath C:\AutomatedLab-VMs\ -DefaultVirtualizationEngine VMWare 

Add-LabVMWareSettings -DataCenterName "Datacenter" -DataStoreName datastore1 -VCenterServerName 192.168.1.30 -Credential $cred -ResourcePoolName Test

if (-not (Get-VDPortgroup -Name VMWareLab)){
    # This should eventually be handled within AutomatedLab
    #New-VDSwitch -Name VMWareVDSwitch -Server 192.168.1.30 -Location datacenter
    New-VDPortgroup -VDSwitch vmwareVDSwitch -Name VMWareLab 
}

Add-LabVirtualNetworkDefinition -Name VMWareLab -VirtualizationEngine VMWare -AddressSpace 192.168.10.0 

Add-LabMachineDefinition -Name test1 -memory 1gb -Processors 1 -OS 'Windows Server 2012 R2 SERVERDATACENTER' -Roles webserver

Install-Lab
