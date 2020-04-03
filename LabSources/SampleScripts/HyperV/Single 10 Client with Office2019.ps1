# Sample script for installing office 365ProPlus as a custom role
$labName = 'SingleMachine'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#Our one and only machine with nothing on it
$role = Get-LabPostInstallationActivity -CustomRole Office2019 -Properties @{ IsoPath = "$labSources\ISOs\en_office_professional_plus_2019_x86_x64_dvd_7ea28c99.iso" }

Add-LabMachineDefinition -Name Win10 -Memory 4GB -Network $labName -OperatingSystem 'Windows 10 Enterprise' -PostInstallationActivity $role

Install-Lab

Show-LabDeploymentSummary -Detailed