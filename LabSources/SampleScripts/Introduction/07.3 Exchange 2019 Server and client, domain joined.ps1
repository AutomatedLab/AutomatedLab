# The is similar to the '05 SQL Server and client, domain joined.ps1' but installs an Exchange 2019 server instead
# of a SQL Server.

# IMPORTANT NOTE: You must have Exchange 2019 ISO or CU already available. Microsoft has limited Exchange 2019 access to VL & MSDN
# so it is not publicly available for download. Also note Exchange 2019 will only run on Windows 2019 Core or Desktop but not Nano

New-LabDefinition -Name LabEx2019 -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2019 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name E1DC1 -Roles RootDC -Memory 1GB

$role = Get-LabPostInstallationActivity -CustomRole Exchange2019 -Properties @{ OrganizationName = 'Contoso'; IsoPath = "$labSources\ISOs\mu_exchange_server_2019_cumulative_update_2_x64_dvd_29ff50e8.iso" }
Add-LabMachineDefinition -Name E1Ex1 -Memory 6GB -PostInstallationActivity $role

Add-LabMachineDefinition -Name E1Client -Memory 2GB -OperatingSystem 'Windows 10 Enterprise'

Install-Lab

Show-LabDeploymentSummary -Detailed
