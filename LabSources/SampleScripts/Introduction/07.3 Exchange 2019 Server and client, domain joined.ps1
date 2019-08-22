# The is similar to the '05 SQL Server and client, domain joined.ps1' but installs an Exchange 2019 server instead
# of a SQL Server.
# IMPORTANT NOTE: You must have Exchange 2019 ISO or CU already available. Microsoft has limited Exchange 2019 access to VL & MSDN
# so it is not a publicly available for download. Also note Exchange 2019 will only run on Windows 2019 Core or Desktop but not Nano

$labName = 'LabEx2019'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV 

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)' 
}

#the first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
$role = Get-LabPostInstallationActivity -CustomRole Exchange2019 -Properties @{ OrganizationName = 'Contoso' }
Add-LabMachineDefinition -Name E1DC1 -Memory 2GB -Network $labName -Roles RootDC 
Add-LabMachineDefinition -Name E1Ex1 -Memory 6GB -PostInstallationActivity $role     
Add-LabMachineDefinition -Name E1Client -Memory 2GB -OperatingSystem 'Windows 10 Enterprise'
    
Install-Lab -NetworkSwitches -BaseImages -VMs -Domains -StartRemainingMachines

Install-Lab -PostInstallations

Show-LabDeploymentSummary -Detailed
    