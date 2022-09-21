param
(
    [string]
    $LabName = ('mnmf-{0:yyyyMMdd}' -f (Get-Date)),
    [string]
    $AzureDefaultLocation = 'West Europe'
)

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

#make the network definition
Add-LabVirtualNetworkDefinition -Name Forest1 -AddressSpace 192.168.41.0/24 -AzureProperties @{ DnsServers = '192.168.41.10'; ConnectToVnets = 'Forest2', 'Forest3'; LocationName = $azureDefaultLocation }
Add-LabVirtualNetworkDefinition -Name Forest2 -AddressSpace 192.168.42.0/24 -AzureProperties @{ DnsServers = '192.168.42.10'; ConnectToVnets = 'Forest1','Forest3'; LocationName = $azureDefaultLocation }
Add-LabVirtualNetworkDefinition -Name Forest3 -AddressSpace 192.168.43.0/24 -AzureProperties @{ DnsServers = '192.168.43.10'; ConnectToVnets = 'Forest1', 'Forest2'; LocationName = $azureDefaultLocation }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name forest1.net -AdminUser Install -AdminPassword 'H1ghS3cure'
Add-LabDomainDefinition -Name a.forest1.net -AdminUser Install -AdminPassword 'H1ghS3cure'
Add-LabDomainDefinition -Name b.forest1.net -AdminUser Install -AdminPassword 'H1ghS3cure'
Add-LabDomainDefinition -Name forest2.net -AdminUser Install -AdminPassword 'H1ghS3cure2'
Add-LabDomainDefinition -Name forest3.net -AdminUser Install -AdminPassword 'H1ghS3cure3'

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2022 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory' = 2GB
}

#--------------------------------------------------------------------------------------------------------------------
$f1 = [pscredential]::new('Install', ('H1ghS3cure' | ConvertTo-SecureString -AsPlainText -Force))
$f2 = [pscredential]::new('Install', ('H1ghS3cure2' | ConvertTo-SecureString -AsPlainText -Force))
$f3 = [pscredential]::new('Install', ('H1ghS3cure3' | ConvertTo-SecureString -AsPlainText -Force))

#Now we define the domain controllers of the first forest. This forest has two child domains.
$roles = Get-LabMachineRoleDefinition -Role RootDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F1DC1 -IpAddress 192.168.41.10 -Network Forest1 -DomainName forest1.net -Roles $roles -PostInstallationActivity $postInstallActivity -InstallationUserCredential $f1

$roles = Get-LabMachineRoleDefinition -Role FirstChildDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name F1ADC1 -IpAddress 192.168.41.11 -Network Forest1 -DomainName a.forest1.net -Roles $roles -PostInstallationActivity $postInstallActivity -InstallationUserCredential $f1

$roles = Get-LabMachineRoleDefinition -Role FirstChildDC
Add-LabMachineDefinition -Name F1BDC1 -IpAddress 192.168.41.12 -Network Forest1 -DomainName b.forest1.net -Roles $roles -InstallationUserCredential $f1

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password 'H1ghS3cure2'

#The next forest is hosted on a single domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F2DC1 -IpAddress 192.168.42.10 -Network Forest2 -DomainName forest2.net -Roles $roles -PostInstallationActivity $postInstallActivity -InstallationUserCredential $f2

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password 'H1ghS3cure3'

#like the third forest - also just one domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC @{ DomainFunctionalLevel = 'Win2008R2'; ForestFunctionalLevel = 'Win2008R2' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F3DC1 -IpAddress 192.168.43.10 -Network Forest3 -DomainName forest3.net -Roles $roles -PostInstallationActivity $postInstallActivity -InstallationUserCredential $f3

Install-Lab

Show-LabDeploymentSummary -Detailed
