# HyperV - SmallLab 2012R2 EX

INSERT TEXT HERE

```powershell
$labName = 'ExSmall1'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.84.0/24

Set-LabInstallationCredential -Username Install -Password Somepass1

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name test1.net -AdminUser Install -AdminPassword Somepass1

#the first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
Add-LabMachineDefinition -Name E1DC1 -Memory 512MB -Network $labName -IpAddress 192.168.84.10 `
    -DnsServer1 192.168.84.10 -DomainName test1.net -Roles RootDC `
    -ToolsPath $labSources\Tools -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

#the second the Exchange 2013 server with the role assigned
$role = Get-LabPostInstallationActivity -CustomRole Exchange2013 -Properties @{ OrganizationName = 'ExOrg' }
Add-LabMachineDefinition -Name E1Ex1 -Memory 4GB -Network $labName -IpAddress 192.168.84.20 `
    -DnsServer1 192.168.84.10 -DomainName test1.net -PostInstallationActivity $role `
    -ToolsPath $labSources\Tools -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

Install-Lab

Show-LabDeploymentSummary -Detailed

```
