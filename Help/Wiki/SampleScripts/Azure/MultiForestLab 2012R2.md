# Azure - MultiForestLab 2012R2

This lab deploys multiple Active Directory forests and domains on Azure with one
virtual network and VNET peering connecting them.

```powershell
$labName = 'MultiForest<SOME UNIQUE DATA>' #THIS NAME MUST BE GLOBALLY UNIQUE

$azureDefaultLocation = 'West Europe' #COMMENT OUT -DefaultLocationName BELOW TO USE THE FASTEST LOCATION

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure

Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

#make the network definition
Add-LabVirtualNetworkDefinition -Name Forest1 -AddressSpace 192.168.41.0/24 -AzureProperties @{ DnsServers = '192.168.41.10'; ConnectToVnets = 'Forest2', 'Forest3'; LocationName = $azureDefaultLocation }
Add-LabVirtualNetworkDefinition -Name Forest2 -AddressSpace 192.168.42.0/24 -AzureProperties @{ DnsServers = '192.168.42.10'; ConnectToVnets = 'Forest1','Forest3'; LocationName = $azureDefaultLocation }
Add-LabVirtualNetworkDefinition -Name Forest3 -AddressSpace 192.168.43.0/24 -AzureProperties @{ DnsServers = '192.168.43.10'; ConnectToVnets = 'Forest1', 'Forest2'; LocationName = $azureDefaultLocation }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name forest1.net -AdminUser Install -AdminPassword 'P@ssw0rd'
Add-LabDomainDefinition -Name a.forest1.net -AdminUser Install -AdminPassword 'P@ssw0rd'
Add-LabDomainDefinition -Name b.forest1.net -AdminUser Install -AdminPassword 'P@ssw0rd'
Add-LabDomainDefinition -Name forest2.net -AdminUser Install -AdminPassword 'P@ssw0rd2'
Add-LabDomainDefinition -Name forest3.net -AdminUser Install -AdminPassword 'P@ssw0rd3'

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
    'Add-LabMachineDefinition:Memory' = 512MB
}

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password P@ssw0rd

#Now we define the domain controllers of the first forest. This forest has two child domains.
$roles = Get-LabMachineRoleDefinition -Role RootDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F1DC1 -IpAddress 192.168.41.10 -Network Forest1 -DomainName forest1.net -Roles $roles -PostInstallationActivity $postInstallActivity

$roles = Get-LabMachineRoleDefinition -Role FirstChildDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name F1ADC1 -IpAddress 192.168.41.11 -Network Forest1 -DomainName a.forest1.net -Roles $roles -PostInstallationActivity $postInstallActivity

$roles = Get-LabMachineRoleDefinition -Role FirstChildDC
Add-LabMachineDefinition -Name F1BDC1 -IpAddress 192.168.41.12 -Network Forest1 -DomainName b.forest1.net -Roles $roles

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password 'P@ssw0rd2'

#The next forest is hosted on a single domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F2DC1 -IpAddress 192.168.42.10 -Network Forest2 -DomainName forest2.net -Roles $roles -PostInstallationActivity $postInstallActivity

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password 'P@ssw0rd3'

#like the third forest - also just one domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008R2'; ForestFunctionalLevel = 'Win2008R2' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F3DC1 -IpAddress 192.168.43.10 -Network Forest3 -DomainName forest3.net -Roles $roles -PostInstallationActivity $postInstallActivity

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Show-LabDeploymentSummary -Detailed

```
