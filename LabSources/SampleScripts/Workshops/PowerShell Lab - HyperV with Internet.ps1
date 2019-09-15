$labName = 'POSH'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.30.10'
    'Add-LabMachineDefinition:DnsServer2' = '192.168.30.11'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}
$PSDefaultParameterValues.Add('Add-LabMachineDefinition:Gateway', '192.168.30.50')

#The PostInstallationActivity is just creating some users
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name POSHDC1 -Memory 512MB -Roles RootDC -IpAddress 192.168.30.10 -PostInstallationActivity $postInstallActivity

#the root domain gets a second domain controller
Add-LabMachineDefinition -Name POSHDC2 -Memory 512MB -Roles DC -IpAddress 192.168.30.11

#file server and router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.30.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name POSHFS1 -Memory 512MB -Roles FileServer, Routing -NetworkAdapter $netAdapter

#web server
Add-LabMachineDefinition -Name POSHWeb1 -Memory 512MB -Roles WebServer -IpAddress 192.168.30.51

<# REMOVE THE COMMENT TO ADD THE SQL SERVER TO THE LAB
#SQL server with demo databases
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso
$role = Get-LabMachineRoleDefinition -Role SQLServer2014 -Properties @{InstallSampleDatabase = 'true'}
Add-LabMachineDefinition -Name POSHSql1 -Memory 1GB -Roles $role -IpAddress 192.168.30.52
#>

<# REMOVE THE COMMENT TO ADD THE EXCHANGE SERVER TO THE LAB
#Exchange 2013
$roles = Get-LabPostInstallationActivity -CustomRole Exchange2013 -Properties @{ OrganizationName = 'TestOrg' }
Add-LabMachineDefinition -Name POSHEx1 -Memory 4GB -PostInstallationActivity $roles -IpAddress 192.168.30.53
#>

<# REMOVE THE COMMENT TO ADD THE DEVELOPMENT CLIENT TO THE LAB
#Development client in the child domain a with some extra tools
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso
Add-LabMachineDefinition -Name POSHClient1 -Memory 1GB -OperatingSystem 'Windows 10 Pro' -Roles VisualStudio2015 -IpAddress 192.168.30.54
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

if (Get-LabVM -ComputerName POSHClient1)
{
    Install-LabSoftwarePackage -Path "$labSources\SoftwarePackages\RSAT Windows 10 x64.msu" -ComputerName POSHClient1
    Invoke-LabCommand -ScriptBlock { Enable-WindowsOptionalFeature -FeatureName RSATClient -Online -NoRestart } -ComputerName POSHClient1
    Restart-LabVM -ComputerName POSHClient1 -Wait
}

Show-LabDeploymentSummary -Detailed
