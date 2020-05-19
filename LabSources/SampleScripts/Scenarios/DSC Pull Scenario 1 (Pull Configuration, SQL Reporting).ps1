<#
This scenario demos a DSC pull server. The lab must have an internet connection in order to download additional required bits. PowerShell 5.0
or greater is required on all DSC pull servers or clients. Please take a look at introduction script '10 ISO Offline Patching.ps1' if you
want to create a Windows Server 2012 base image with PowerShell 5.

First a domain controller is setup. Then AutomatedLab (AL) configures the routing, a web server and the CA. This scenario demos
a DSC pull server that is encrypting the network communication using SSL. Fenor this AL creates a new certificate template
(DSC Pull Server SSL. The DSC pull server requests a certificate using this template and configures DSC accordingly.

In this scenario the DSC pull server does not store the node registration data and reports on the local machine but in a SQL database on DSQL1.


AL also creates a default DSC configuration that creates a test file on each DSC client. The name of the file is TestFile_<PullServer>.
The pull server the configuration is coming from is part of the file name as a client can have multiple pull servers (partial configuraion).
#>
$labName = 'DSCLab2'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

Clear-Host
#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
}

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name DDC1 -Roles RootDC -PostInstallationActivity $postInstallActivity

#router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name DRouter -Roles Routing -NetworkAdapter $netAdapter

#CA
Add-LabMachineDefinition -Name DCA1 -Roles CaRoot


#SQL Server
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labSources\ISOs\en_sql_server_2016_standard_with_service_pack_2_x64_dvd_12124191.iso
Add-LabMachineDefinition -Name DSQL -Roles SQLServer2016 -Memory 2GB

#DSC Pull Server
$role = Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{ DatabaseEngine = 'SQL'; SqlServer = 'DSQL'; DatabaseName = 'DSC' }
Add-LabMachineDefinition -Name DPull1 -Roles $role

#DSC Pull Clients
Add-LabMachineDefinition -Name DServer1
Add-LabMachineDefinition -Name DServer2

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Install-LabWindowsFeature -ComputerName DPULL1 -FeatureName Web-Mgmt-Console

Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscPullServer\CreateDscSqlDatabase.ps1 -ComputerName DSQL
Invoke-LabCommand -ActivityName 'Create SQL Database for DSC Reporting' -ComputerName DSQL -ScriptBlock {
    C:\CreateDscSqlDatabase.ps1 -DomainAndComputerName CONTOSO\DPULL1
}

Install-LabDscClient -All

Show-LabDeploymentSummary -Detailed
