# HyperV - PKI Simple

INSERT TEXT HERE

```powershell
$labName = 'PKISmall1'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.86.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name test1.net -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DnsServer1'= '192.168.86.10'
    'Add-LabMachineDefinition:Memory'= 512MB
    'Add-LabMachineDefinition:DomainName'= 'test1.net'
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
}

#the first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
$role = Get-LabMachineRoleDefinition -Role RootDC
Add-LabMachineDefinition -Name P1DC1 -IpAddress 192.168.86.10 -Roles $role

#the second will be a member server configured as Root CA server. Everything in $labSources\Tools get copied to the machine's Windows folder
$role = Get-LabMachineRoleDefinition -Role CaRoot
Add-LabMachineDefinition -Name P1CA1 -IpAddress 192.168.86.20 -Roles $role

#Now the actual work begins. First the virtual network adapter is created and then the base images per OS
#All VMs are diffs from the base.
Install-Lab -NetworkSwitches -BaseImages -VMs

#This sets up all domains / domain controllers
Install-Lab -Domains

#Install CA server(s)
Install-Lab -CA

Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning

Show-LabDeploymentSummary -Detailed

```
