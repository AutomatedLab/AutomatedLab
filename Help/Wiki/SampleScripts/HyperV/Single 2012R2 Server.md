# HyperV - Single 2012R2 Server

INSERT TEXT HERE

```powershell
$labName = 'SingleMachine'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.70.0/24

Set-LabInstallationCredential -Username Install -Password Somepass1

#Our one and only machine with nothing on it
Add-LabMachineDefinition -Name TestServer1 -Memory 1GB -Network $labName -IpAddress 192.168.70.10 `
    -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

Install-Lab

Show-LabDeploymentSummary -Detailed

```
