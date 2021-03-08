# Introduction - 06 SQL Server and client, domain joined

INSERT TEXT HERE

```powershell
#This intro script is extending '03 Single domain-joined server.ps1'. An additional ISO is added to the lab which is required to install SQL Server 2014. The script makes
#use of the $PSDefaultParameterValues feature introduced in PowerShell version 4. Settings that are the same for all machines can be summarized
#that way and still be overwritten when necessary.

New-LabDefinition -Name Lab1 -DefaultVirtualizationEngine HyperV

Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name DC1 -Roles RootDC

Add-LabMachineDefinition -Name SQL1 -Roles SQLServer2014

Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Pro'

Install-Lab

Show-LabDeploymentSummary -Detailed

```
