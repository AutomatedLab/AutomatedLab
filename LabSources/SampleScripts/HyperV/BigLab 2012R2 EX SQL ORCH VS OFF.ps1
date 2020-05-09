$labName = 'Test3'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.50.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name vm.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name a.vm.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name b.vm.net -AdminUser Install -AdminPassword Somepass1

#these images are used to install the machines
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso
Add-LabIsoImageDefinition -Name Orchestrator2012 -Path $labSources\ISOs\en_system_center_2012_orchestrator_with_sp1_x86_dvd_1345499.iso
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso
Add-LabIsoImageDefinition -Name Office2013 -Path $labSources\ISOs\en_office_professional_plus_2013_with_sp1_x86_dvd_3928181.iso

Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DnsServer1' = '192.168.50.10'
    'Add-LabMachineDefinition:DnsServer2' = '192.168.50.11'
    'Add-LabMachineDefinition:Memory' = 512MB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
}

#the first machine is the root domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2012R2'; ForestFunctionalLevel = 'Win2012R2' }
#The PostInstallationActivity is just creating some users
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name T3RDC1 -IpAddress 192.168.50.10 -DomainName vm.net -Roles $roles -PostInstallationActivity $postInstallActivity

#the root domain gets a second domain controller
$roles = Get-LabMachineRoleDefinition -Role DC
Add-LabMachineDefinition -Name T3RDC2 -IpAddress 192.168.50.11 -DomainName vm.net -Roles $roles

#this is the first domain controller of the child domain 'a' defined above
#The PostInstallationActivity is filling the domain with some life.
#At the end about 6000 users are available with OU and manager hierarchy as well as a bunch of groups
$roles = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'vm.net'; NewDomain = 'a'; DomainFunctionalLevel = 'Win2012R2' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name T3ADC1 -IpAddress 192.168.50.20 -DomainName a.vm.net -Roles $roles -PostInstallationActivity $postInstallActivity

#2nd domain controller for the child domain 'a'
$roles = Get-LabMachineRoleDefinition -Role DC
Add-LabMachineDefinition -Name T3ADC2 -IpAddress 192.168.50.21 -DomainName a.vm.net -Roles $roles

#first domain controller for the 2nd child domain 'b'
$roles = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'vm.net'; NewDomain = 'b'; DomainFunctionalLevel = 'Win2012R2' }
Add-LabMachineDefinition -Name T3BDC1 -IpAddress 192.168.50.30 -DomainName b.vm.net -Roles $roles

#2nd domain controller for the child domain 'b'
$roles = Get-LabMachineRoleDefinition -Role DC
Add-LabMachineDefinition -Name T3BDC2 -IpAddress 192.168.50.31 -DomainName b.vm.net -Roles $roles

#file server in the child domain 'a'
$roles = (Get-LabMachineRoleDefinition -Role FileServer)
Add-LabMachineDefinition -Name T3AFS1 -IpAddress 192.168.50.50 -DomainName a.vm.net -Roles $roles

#A SQL server in the child domain 'a' with demo databases
$roles = Get-LabMachineRoleDefinition -Role SQLServer2014, VisualStudio2015 -Properties @{InstallSampleDatabase = 'true'}
Add-LabMachineDefinition -Name T3ASQL1 -Memory 1GB -IpAddress 192.168.50.51 -DomainName a.vm.net -Roles $roles

#A server with System Center Orchestrator 2012
$roles = (Get-LabMachineRoleDefinition -Role Orchestrator2012 -Properties @{ DatabaseServer = ((Get-LabMachineDefinition | Where-Object { $_.Roles.Name -eq 'SQLServer2014' })[0].Name); DatabaseName = 'Orchestrator'; ServiceAccount = 'OrchService'; ServiceAccountPassword = 'Somepass1' })
Add-LabMachineDefinition -Name T3AORCH1 -Memory 1GB -IpAddress 192.168.50.55 -DomainName a.vm.net -Roles $roles

Add-LabDiskDefinition -Name ExDataDisk -DiskSizeInGb 50
#Exchange Server in the child domain 'a'
$roles = Get-LabPostInstallationActivity -CustomRole Exchange2013 -Properties @{ OrganizationName = 'TestOrg' }
Add-LabMachineDefinition -Name T3AEX1 -Memory 4GB -IpAddress 192.168.50.52 -DomainName a.vm.net -PostInstallationActivity $roles -DiskName ExDataDisk

#Development client in the child domain a with some extra tools
$roles = Get-LabMachineRoleDefinition -Role VisualStudio2015, Office2013
Add-LabMachineDefinition -Name T3Client1 -Memory 2GB -IpAddress 192.168.50.85 -OperatingSystem 'Windows 10 Pro' -DomainName a.vm.net -Roles $roles

#Another client in the child domain 'a'
$roles = Get-LabMachineRoleDefinition -Role Office2013
Add-LabMachineDefinition -Name T3Client2 -Memory 2GB -IpAddress 192.168.50.86 -OperatingSystem 'Windows 10 Pro' -DomainName a.vm.net -Roles $roles

#Now the actual work begins.
Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
#Install Reflector to the second VisualStudio2015 machines
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName (Get-LabVM -Role VisualStudio2015)[1] -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Show-LabDeploymentSummary -Detailed
