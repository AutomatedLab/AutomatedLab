# Scenarios - TFS 2017 Deployment

INSERT TEXT HERE

```powershell
New-LabDefinition -Name TFS2017 -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 2GB
    'Add-LabMachineDefinition:Tools'          = "$labsources\Tools"
}

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

# As usual, use the role name as the ISO image definition name
Add-LabIsoImageDefinition -Name Tfs2017 -Path $labsources\ISOs\en_team_foundation_server_2017_update_3_x64_dvd_11697950.iso
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labsources\ISOs\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso

Add-LabMachineDefinition -Name tfs2DC1 -Roles RootDC -Memory 1GB
Add-LabMachineDefinition -Name tfs2SQL1 -ROles SQLServer2016

# If no properties are used, we automatically select a SQL server, use port 8080 and name the initial
# Collection AutomatedLab
$role = Get-LabMachineRoleDefinition -Role Tfs2017 -Properties @{
    Port = '8081'
    DbServer = "tfs1SQL1"
    InitialCollection = 'CustomCollection'
}
Add-LabMachineDefinition -Name tfs2Srv1 -Roles $role -Memory 4GB

# If no properties are used, we automatically bind to the first TFS Server in the lab, use port 9090 and 2 build agents
# If a TFS server is used, the fitting installation (TFS2015 or 2017) will be used for the build agent
Add-LabMachineDefinition -Name tfs2Build1 -Roles TfsBuildWorker

Install-Lab

Show-LabDeploymentSummary -Detailed
```
