$labName = 'Test5'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.71.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name test2.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name child1.test2.net -AdminUser Install -AdminPassword Somepass1

#these images are used to install the machines
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso

Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DnsServer1'= '192.168.71.10'
    'Add-LabMachineDefinition:DnsServer2'= '192.168.71.11'
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
    'Add-LabMachineDefinition:DomainName'= 'child1.test2.net'
}

#the first machine is the root domain controller
$role = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008'; ForestFunctionalLevel = 'Win2008' }
#The PostInstallationActivity is just creating some users
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name T2DC1 -Memory 512MB -IpAddress 192.168.71.10 -DomainName test2.net -Roles $role -PostInstallationActivity $postInstallActivity

#this is the first domain controller of the child domain 'child1' defined above
#The PostInstallationActivity is filling the domain with some life.
#At the end about 6000 users are available with OU and manager hierarchy as well as a bunch of groups
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'test2.net'; NewDomain = 'child1'; DomainFunctionalLevel = 'Win2012R2' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name T2DC2 -Memory 512MB -IpAddress 192.168.71.11 -Roles $role

#This machine will serve all Exchange roles
$role = Get-LabPostInstallationActivity -CustomRole Exchange2013 -Properties @{ OrganizationName = 'ExOrg' }
Add-LabMachineDefinition -Name T2Ex1 -Memory 4GB -Processors 2 -IpAddress 192.168.71.50 -PostInstallationActivity $role

#This will be the SQL server with the usual demo databases
$role = Get-LabMachineRoleDefinition -Role SQLServer2014 -Properties @{InstallSampleDatabase = 'true'}
Add-LabMachineDefinition -Name T2Sql1 -Memory 1GB -Processors 2 -IpAddress 192.168.71.51 -Roles $role

#Client with Visual Studio 2015
$role = Get-LabMachineRoleDefinition -Role VisualStudio2015
Add-LabMachineDefinition -Name T2Client1 -Memory 2GB -Processors 2 -IpAddress 192.168.71.55 -Roles $role

Install-Lab

#Install software to all lab machines
$packs = @()
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
$packs += Get-LabSoftwarePackage -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S

Install-LabSoftwarePackages -Machine (Get-LabVM -All) -SoftwarePackage $packs

#Install Reflector to the first VisualStudio2015 machines
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName (Get-LabVM -Role VisualStudio2015)[0].Name

Show-LabDeploymentSummary -Detailed
