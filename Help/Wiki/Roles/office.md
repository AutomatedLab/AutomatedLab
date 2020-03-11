# Office 2013 and Office 2016

The Office 2013 Role is installing Office 2013 in a predefined standard configuration. If not customized, Office 2013 is installed in the computer licensing mode. There is an option to switch to shared computer activation.

## Role Assignment
The role can be assigned to a machine like this:
```powershell
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles Office2013
```

## Installation Process
The installation is covered when calling 'Install-Lab' without using additional parameters. To start only the Office 2013 installation, you can use 'Install-Lab -Office2013'.

## Requirements
In order to install this role, the Office 2013 ISO image needs to be added to the lab. Adding the ISO works like this:

```powershell
Add-LabIsoImageDefinition -Name Office2013 -Path E:\LabSources\ISOs\en_office_professional_plus_2013_with_sp1_x86_dvd_3928181.iso
```

The Office 2016 Role is installing Office 2016 in a predefined standard configuration. If not customized, Office 2016 is installed in the computer licensing mode. There is an option to switch to shared computer activation.

## Role Assignment
The role can be assigned directly to a machine like this:
```powershell
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles Office2016
```
Or if you want to change the licensing option, the role needs to be created first by means of Get-LabMachineRoleDefinition:
```powershell
$role = Get-LabMachineRoleDefinition -Role Office2016 -Properties @{ SharedLicense = $true }
Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Enterprise' -Roles $role
```

## Installation Process
The installation is covered when calling 'Install-Lab' without using additional parameters. To start only the Office 2016 installation, you can use 'Install-Lab -Office2016'.

## Requirements
In order to install this role, the Office 2016 ISO image needs to be added to the lab. Adding the ISO works like this:

```powershell
Add-LabIsoImageDefinition -Name Office2016 -Path E:\LabSources\ISOs\en_office_professional_plus_2016_x86_x64_dvd_6962141.iso
```