New-LabDefinition -Name TFS2015 -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:DomainName'      = 'contoso.com'
    'Add-LabMachineDefinition:Memory'          = 2GB
    'Add-LabMachineDefinition:Tools'          = "$labsources\Tools"
}

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

# As usual, use the role name as the ISO image definition name
Add-LabIsoImageDefinition -Name Tfs2015 -Path $labsources\ISOs\en_team_foundation_server_2015_update_4_x86_x64_dvd_11701753.iso
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labsources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso

Add-LabMachineDefinition -Name tfs1DC1 -Roles RootDC -Memory 1GB
Add-LabMachineDefinition -Name tfs1SQL1 -ROles SQLServer2014

$role = Get-LabMachineRoleDefinition -Role Tfs2015 -Properties @{
    DbServer = "tfs1SQL1" # Use correct SQL Edition according to the product compatibility matrix!
}
Add-LabMachineDefinition -Name tfs1Srv1 -Roles $role -Memory 4GB

$role = Get-LabMachineRoleDefinition -Role TfsBuildWorker -Properties @{
    TfsServer = "tfs1Srv1"
}
Add-LabMachineDefinition -Name tfsBuild1 -Roles $role

Install-Lab

Show-LabDeploymentSummary -Detailed