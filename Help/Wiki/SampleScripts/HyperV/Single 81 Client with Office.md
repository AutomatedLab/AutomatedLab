# HyperV - Single 81 Client with Office

INSERT TEXT HERE

```powershell
$labName = 'SingleMachine'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.70.0/24

#read all OS ISOs in the LabSources folder and add the Office 2013 and Visual Studio 2013 ISO
Add-LabIsoImageDefinition -Name Office2013 -Path $labSources\ISOs\en_office_professional_plus_2013_with_sp1_x86_dvd_3928181.iso

Set-LabInstallationCredential -Username Install -Password Somepass1

#Our one and only machine with nothing on it
Add-LabMachineDefinition -Name TestClient2 -Memory 2GB -Network $labName -IpAddress 192.168.70.13 `
    -OperatingSystem 'Windows 8.1 Pro' -Roles Office2013

Install-Lab

Show-LabDeploymentSummary -Detailed

```
