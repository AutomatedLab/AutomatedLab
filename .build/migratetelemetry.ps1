New-AzResourceGroup -Name AutomatedLabTelemetry -Location westeurope
New-AzResourceGroupDeployment -ResourceGroupName AutomatedLabTelemetry -TemplateFile .\.build\telemetry.json -runbookUri 'FILL ME IN'-sqlAdminPassword ('FILL ME IN' | ConvertTo-SecureString -aspl -forc)
$crd = Get-Crdential
$source = 'automatedlab.database.windows.net'
$destination = 'sqlngmzvocoqhoxk.database.windows.net'
Copy-DbaDbTableData $source $crd -Destination $destination -DestinationSqlCredential $crd -DestinationDatabase Telly -Database Telly -Table dbo.roles -AutoCreateTable
Copy-DbaDbTableData $source $crd -Destination $destination -DestinationSqlCredential $crd -DestinationDatabase Telly -Database Telly -Table dbo.functionCalled -AutoCreateTable
Copy-DbaDbTableData $source $crd -Destination $destination -DestinationSqlCredential $crd -DestinationDatabase Telly -Database Telly -Table dbo.labRemoveInfo -AutoCreateTable
Copy-DbaDbTableData $source $crd -Destination $destination -DestinationSqlCredential $crd -DestinationDatabase Telly -Database Telly -Table dbo.labInstallInfo -AutoCreateTable
Copy-DbaDbTableData $source $crd -Destination $destination -DestinationSqlCredential $crd -DestinationDatabase Telly -Database Telly -Table dbo.labinfo -AutoCreateTable

<#
Manual:
- AppInsights -> Diagnostic Settings -> [x] Events, Archive to Storage Account
- Create Azure SQL firewall rules to migrate tables
- Create Power BI Workspace
- Publish pbix to workspace
- Update source credentials and refresh interval
- Publish Report to web
- Update links in readme and wiki
#>