$labName = 'Test4'

$labSources = Get-LabSourcesLocation

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.41.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name forest1.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name a.forest1.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name b.forest1.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name forest2.net -AdminUser Install -AdminPassword Somepass2
Add-LabDomainDefinition -Name forest3.net -AdminUser Install -AdminPassword Somepass3

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2012 R2 SERVERDATACENTER'
    'Add-LabMachineDefinition:Memory'= 512MB
}

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass1

#Now we define the domain controllers of the first forest. This forest has two child domains.
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F1DC1 -DomainName forest1.net -Roles RootDC -PostInstallationActivity $postInstallActivity

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name F1ADC1 -DomainName a.forest1.net -Roles FirstChildDC -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name F1BDC1 -DomainName b.forest1.net -Roles FirstChildDC

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass2

#The next forest is hosted on a single domain controller
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F2DC1 -DomainName forest2.net -Roles RootDC -PostInstallationActivity $postInstallActivity

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass3

#like the third forest - also just one D
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008R2'; ForestFunctionalLevel = 'Win2008R2' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F3DC1 -DomainName forest3.net -Roles $roles -PostInstallationActivity $postInstallActivity

Install-Lab

#Install software to all lab machines
$packs = @()
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\ClassicShell.exe -CommandLine '/quiet ADDLOCAL=ClassicStartMenu'
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S

Install-LabSoftwarePackages -Machine (Get-LabMachine -All) -SoftwarePackage $packs

Show-LabInstallationTime