# SCCM

## Defining the role

``` PowerShell
$sccmRole = Get-LabPostInstallationActivity -CustomRole SCCM -Properties @{
    SccmSiteCode = "CM1"
    SccmBinariesDirectory = "$labSources\SoftwarePackages\SCCM1702"
    SccmPreReqsDirectory = "$labSources\SoftwarePackages\SCCMPreReqs"
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
    SqlServerName = 'SQL1'
}

Add-LabMachineDefinition -Name SCCM1 -Memory 4GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'  -DomainName contoso.com -PostInstallationActivity $sccmRole
```

Requires a SQL Server with collation 'SQL_Latin1_General_CP1_CI_AS'

``` PowerShell
$sqlRole = Get-LabMachineRoleDefinition -Role SQLServer2017 -Properties @{ Collation = 'SQL_Latin1_General_CP1_CI_AS' }
Add-LabMachineDefinition -Name SQL1 -Memory 2GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DomainName contoso.com -Roles $sqlRole
```