# HyperV - Single 81 Client

INSERT TEXT HERE

```powershell
$labName = 'SingleMachine'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.70.0/24

Set-LabInstallationCredential -Username Install -Password Somepass1

#Our one and only machine with nothing on it
Add-LabMachineDefinition -Name TestClient1 -Memory 1GB -Network $labName -IpAddress 192.168.70.12 `
    -OperatingSystem 'Windows 8.1 Pro'

Install-Lab

Show-LabDeploymentSummary -Detailed

```
