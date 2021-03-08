# Workshops - ADPowerShellWorkshopLab

INSERT TEXT HERE

```powershell
$labName = 'ADPowerShell'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.50.0/24

Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:UserLocale'= 'de-DE'
    'Add-LabMachineDefinition:TimeZone'= 'W. Europe Standard Time'
    'Add-LabMachineDefinition:Memory' = 512MB
}

Add-LabMachineDefinition -Name ADRDC1
Add-LabMachineDefinition -Name ADRDC2
Add-LabMachineDefinition -Name ADADC1
Add-LabMachineDefinition -Name ADADC2
Add-LabMachineDefinition -Name ADBDC1
Add-LabMachineDefinition -Name ADBDC2
Add-LabMachineDefinition -Name ADServer1
Add-LabMachineDefinition -Name ADClient1 -Memory 2GB

#------- Machines for 2nd and 3rd forest ------------------------------------------------------

Add-LabMachineDefinition -Name ADXDC1
Add-LabMachineDefinition -Name ADXDC2
Add-LabMachineDefinition -Name ADYDC1
Add-LabMachineDefinition -Name ADYDC2

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM -All
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Winrar.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winpcap-nmap.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Wireshark.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Install-LabWindowsFeature -ComputerName ADClient1 -FeatureName RSAT -IncludeAllSubFeature

Show-LabDeploymentSummary -Detailed
```
