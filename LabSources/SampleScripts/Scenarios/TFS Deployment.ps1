New-LabDefinition -Name TFS -DefaultVirtualizationEngine HyperV

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

# As usual, use the role name as the ISO image definition name
Add-LabIsoImageDefinition -Name Tfs2017 -Path $labsources\ISOS\en_team_foundation_server_2017_x64_dvd_9579548.iso
Add-LabIsoImageDefinition -Name Tfs2015 -Path $labsources\ISOS\en_team_foundation_server_2015_update_4_x86_x64_dvd_10284962.iso
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labsources\ISOS\en_sql_server_2014_enterprise_edition_with_service_pack_2_x64_dvd_8962401.iso
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labsources\ISOS\en_sql_server_2016_enterprise_x64_dvd_8701793.iso

Add-LabMachineDefinition -Name tfsDC1 -Roles RootDC -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTERCORE' -Memory 1GB
Add-LabMachineDefinition -Name tfsSQL1 -ROles SQLServer2016 -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTER' -Memory 2GB
Add-LabMachineDefinition -Name tfsSQL2 -ROles SQLServer2014 -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTER' -Memory 2GB

# If no properties are used, we automatically select a SQL server, use port 8080 and name the initial
# Collection AutomatedLab
$role = Get-LabMachineRoleDefinition -Role Tfs2017 -Properties @{
    Port = '8081'
    DbServer = "tfsSQL1"
    InitialCollection = 'CustomCollection'
}
Add-LabMachineDefinition -Name tfsSrv1 -Roles $role -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTER' -Memory 4GB

$role = Get-LabMachineRoleDefinition -Role Tfs2015 -Properties @{
    DbServer = "tfsSQL2" # Use correct SQL Edition according to the product compatibility matrix!
}
Add-LabMachineDefinition -Name tfsSrv2 -Roles $role -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTER' -Memory 4GB

# If no properties are used, we automatically bind to the first TFS Server in the lab, use port 9090 and 2 build agents
# If a TFS server is used, the fitting installation (TFS2015 or 2017) will be used for the build agent
Add-LabMachineDefinition -Name tfsBuild1 -Roles TfsBuildWorker -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTERCORE' -Memory 2GB

$role = Get-LabMachineRoleDefinition -Role TfsBuildWorker -Properties @{
    TfsServer = "tfsSrv2"
}
Add-LabMachineDefinition -Name tfsBuild2 -Roles $role -DomainName contoso.com -OperatingSystem 'Windows Server 2016 SERVERDATACENTERCORE' -Memory 2GB

Install-Lab
