$labName = 'POSH<SOME UNIQUE DATA>' #THIS NAME MUST BE GLOBALLY UNIQUE

$azureResourceManagerProfile = '<PATH TO YOUR AZURE RM PROFILE>' #IF YOU HAVE NO PROFILE FILE, CALL Save-AzureRmContext
$azureDefaultLocation = 'West Europe' #COMMENT OUT -DefaultLocationName BELOW TO USE THE FASTEST LOCATION

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure

Add-LabAzureSubscription -Path $azureResourceManagerProfile -DefaultLocationName $azureDefaultLocation

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.30.10'
    'Add-LabMachineDefinition:DnsServer2' = '192.168.30.11'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
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
Add-LabMachineDefinition -Name POSHFS1 -Memory 512MB -Roles $roles -IpAddress 192.168.30.50

#web server
$roles = Get-LabMachineRoleDefinition -Role WebServer
Add-LabMachineDefinition -Name POSHWeb1 -Memory 512MB -Roles $roles -IpAddress 192.168.30.51

<# REMOVE THE COMMENT TO ADD THE SQL SERVER TO THE LAB
#SQL server with demo databases
$roles = Get-LabMachineRoleDefinition -Role SQLServer2014
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName InstallSampleDBs.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareSqlServer -KeepFolder
Add-LabMachineDefinition -Name POSHSql1 -Memory 1GB -Roles $roles -IpAddress 192.168.30.52 -PostInstallationActivity $postInstallActivity
#>

<# REMOVE THE COMMENT TO ADD THE EXCHANGE SERVER TO THE LAB
#Exchange 2013
$roles = Get-LabMachineRoleDefinition -Role Exchange2013 -Properties @{ OrganizationName = 'TestOrg' }
Add-LabMachineDefinition -Name POSHEx1 -Memory 4GB -Roles $roles -IpAddress 192.168.30.53
#>

<# REMOVE THE COMMENT TO ADD THE DEVELOPMENT CLIENT TO THE LAB
#Development client in the child domain a with some extra tools
Add-LabMachineDefinition -Name POSHClient1 -Memory 1GB -Role VisualStudio2013 -IpAddress 192.168.30.54
#>

Install-Lab

<# REMOVE THE COMMENT TO INSTALL CLASSIC SHELL, NOTEPAD++ AND WINRAR ON ALL LAB MACHINES
#Install software to all lab machines
$machines = Get-LabMachine
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\ClassicShell.exe -CommandLine '/quiet ADDLOCAL=ClassicStartMenu' -AsJob
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

Invoke-LabCommand -ActivityName AddDevAsAdmin -ComputerName (Get-LabMachine -ComputerName POSHFS1) -ScriptBlock $cmd
#endregion

Install-LabWindowsFeature -ComputerName PoshClient1 -FeatureName RSAT -IncludeAllSubFeature

#stop all machines to save money
Stop-LabVM -All -Wait

Show-LabDeploymentSummary -Detailed
