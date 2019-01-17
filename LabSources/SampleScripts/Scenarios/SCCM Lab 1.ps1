#This lab installs the SCCM role (1702). All required resources except the SQL Server ISO are downloaded during the deployment.

New-LabDefinition -Name SccmLab1 -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath' = "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
}

Add-LabIsoImageDefinition -Name SQLServer2017 -Path $labSources\ISOs\en_sql_server_2017_standard_x64_dvd_11294407.iso

Add-LabMachineDefinition -Name sDC1 -Memory 1GB -Roles RootDC

$sccmRole = Get-LabPostInstallationActivity -CustomRole SCCM -Properties @{
    SccmSiteCode = "S01"
    SccmBinariesDirectory = "$labSources\SoftwarePackages\SCCM1702"
    SccmPreReqsDirectory = "$labSources\SoftwarePackages\SCCMPreReqs"
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
    SqlServerName = 'sSQL1'
}
Add-LabMachineDefinition -Name sSCCM1 -Memory 4GB -DomainName contoso.com -PostInstallationActivity $sccmRole

$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{ Collation = 'SQL_Latin1_General_CP1_CI_AS' }
Add-LabMachineDefinition -Name sSQL1 -Memory 2GB -Roles $sqlRole

Add-LabMachineDefinition -Name sServer1 -Memory 2GB

Install-Lab

Show-LabDeploymentSummary -Detailed
