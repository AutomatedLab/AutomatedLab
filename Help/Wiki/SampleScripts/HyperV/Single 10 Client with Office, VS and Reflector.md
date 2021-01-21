# HyperV - Single 10 Client with Office, VS and Reflector

INSERT TEXT HERE

```powershell
$labName = 'SingleMachine'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.70.0/24

#read all OS ISOs in the LabSources folder and add the Office 2013 and Visual Studio 2013 ISO
Add-LabIsoImageDefinition -Name Office2013 -Path $labSources\ISOs\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso

Set-LabInstallationCredential -Username Install -Password Somepass1

#Our one and only machine with nothing on it
Add-LabMachineDefinition -Name TestClient3 -Memory 2GB -Network $labName -IpAddress 192.168.70.14 `
    -OperatingSystem 'Windows 10 Pro' -Roles Office2013, VisualStudio2015

#Now the actual work begins. First the virtual network adapter is created and then the base images per OS
#All VMs are diffs from the base.
Install-Lab

#Install software to all lab machines
$packs = @()
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S

Install-LabSoftwarePackages -Machine (Get-LabVM -All) -SoftwarePackage $packs

#Install Reflector to the first VisualStudio machine
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName (Get-LabVM -Role VisualStudio2015)

Show-LabDeploymentSummary -Detailed

```
