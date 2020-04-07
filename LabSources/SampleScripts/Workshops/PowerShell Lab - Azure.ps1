$labName = 'POSH<SOME UNIQUE DATA>' #THIS NAME MUST BE GLOBALLY UNIQUE

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
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword 'P@ssw0rd!1'

Set-LabInstallationCredential -Username Install -Password 'P@ssw0rd!1'

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.30.10'
    'Add-LabMachineDefinition:DnsServer2' = '192.168.30.11'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

#the first machine is the root domain controller
$roles = Get-LabMachineRoleDefinition -Role RootDC
#The PostInstallationActivity is just creating some users
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name POSHDC1 -Memory 512MB -Roles $roles -IpAddress 192.168.30.10 -PostInstallationActivity $postInstallActivity

#the root domain gets a second domain controller
$roles = Get-LabMachineRoleDefinition -Role DC
Add-LabMachineDefinition -Name POSHDC2 -Memory 512MB -Roles $roles -IpAddress 192.168.30.11

#file server
$roles = Get-LabMachineRoleDefinition -Role FileServer
Add-LabDiskDefinition -Name premium1 -DiskSizeInGb 128
Add-LabDiskDefinition -Name premium2 -DiskSizeInGb 128
# Using SSD storage for the additional disks
Add-LabMachineDefinition -Name POSHFS1 -Memory 512MB -DiskName premium1,premium2 -Roles $roles -IpAddress 192.168.30.50 -AzureProperties @{StorageSku = 'StandardSSD_LRS'}

#web server
$roles = Get-LabMachineRoleDefinition -Role WebServer
Add-LabMachineDefinition -Name POSHWeb1 -Memory 512MB -Roles $roles -IpAddress 192.168.30.51

<# REMOVE THE COMMENT TO ADD THE SQL SERVER TO THE LAB
#SQL server with demo databases
$role = Get-LabMachineRoleDefinition -Role SQLServer2014 @{InstallSampleDatabase = 'true'}
Add-LabMachineDefinition -Name POSHSql1 -Memory 1GB -Roles $role -IpAddress 192.168.30.52
#>

<# REMOVE THE COMMENT TO ADD THE SQL SERVER TO THE LAB - Using the BYOL licensing scheme
#SQL server with demo databases
$role = Get-LabMachineRoleDefinition -Role SQLServer2014 @{InstallSampleDatabase = 'true'}
Add-LabMachineDefinition -Name POSHSql1 -Memory 1GB -Roles $role -IpAddress 192.168.30.52 -AzureProperties @{'UseByolImage' = 'True'}
#>

<# REMOVE THE COMMENT TO ADD THE EXCHANGE SERVER TO THE LAB
#Exchange 2013
$r = Get-LabPostInstallationActivity -CustomRole Exchange2013 -Properties @{ OrganizationName = 'TestOrg' }
Add-LabMachineDefinition -Name POSHEx1 -Memory 4GB -IpAddress 192.168.30.53 -PostInstallationActivity $r
#>

<# REMOVE THE COMMENT TO ADD THE DEVELOPMENT CLIENT TO THE LAB
#Development client in the child domain a with some extra tools
Add-LabMachineDefinition -Name POSHClient1 -Memory 1GB -IpAddress 192.168.30.54
#>

Install-Lab

<# REMOVE THE COMMENT TO INSTALL NOTEPAD++ AND WINRAR ON ALL LAB MACHINES
#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null
#>

#region Make the Dev user local administrator on the file server
$cmd = {
    $domain = [System.Environment]::UserDomainName
    $userName = 'Dev'

    $trustee = "WinNT://$domain/$userName"

    ([ADSI]"WinNT://$(HOSTNAME.EXE)/Administrators,group").Add($trustee)
}

Invoke-LabCommand -ActivityName AddDevAsAdmin -ComputerName (Get-LabVM -ComputerName POSHFS1) -ScriptBlock $cmd
#endregion

Install-LabWindowsFeature -ComputerName PoshClient1 -FeatureName RSAT -IncludeAllSubFeature

#stop all machines to save money
Stop-LabVM -All -Wait

Show-LabDeploymentSummary -Detailed
