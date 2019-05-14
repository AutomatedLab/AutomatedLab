function Get-ConfigSet
{
    return Get-CimInstance -Namespace 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin' -Class MSReportServer_ConfigurationSetting -ComputerName localhost
}

$configSet = Get-ConfigSet

if (-not $configSet.IsInitialized)
{
    # Get the ReportServer and ReportServerTempDB creation script
    $dbScript = $configSet.GenerateDatabaseCreationScript('ReportServer', 1033, $false).Script

    $conn = New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList ($env:ComputerName)
    $conn.ApplicationName = 'SCOB Script'
    $conn.StatementTimeout = 0
    $conn.Connect()
    $smo = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList ($conn)

    # Create the ReportServer and ReportServerTempDB databases
    $db = $smo.Databases['master']
    [void]$db.ExecuteNonQuery($dbScript)

    # Set permissions for the databases
    $dbScript = $configSet.GenerateDatabaseRightsScript($configSet.WindowsServiceIdentityConfigured, 'ReportServer', $false, $true).Script
    [void]$db.ExecuteNonQuery($dbScript)

    # Set the database connection info
    [void]$configSet.SetDatabaseConnection('(local)', 'ReportServer', 2, '', '')

    [void]$configSet.SetVirtualDirectory('ReportServerWebService', 'ReportServer', 1033)
    [void]$configSet.ReserveURL('ReportServerWebService', 'http://+:80', 1033)

    [void]$configSet.SetVirtualDirectory('ReportServerWebApp', 'Reports', 1033)
    [void]$configSet.ReserveURL('ReportServerWebApp', 'http://+:80', 1033)

    [void]$configSet.InitializeReportServer($configSet.InstallationID)

    # Re-start services
    [void]$configSet.SetServiceState($false, $false, $false)
    Restart-Service -InputObject $configSet.ServiceName
    [void]$configSet.SetServiceState($true, $true, $true)

    # Update the current configuration
    $configSet = Get-ConfigSet

    [void]$configSet.IsReportManagerEnabled
    [void]$configSet.IsInitialized
    [void]$configSet.IsWebServiceEnabled
    [void]$configSet.IsWindowsServiceEnabled
    [void]$configSet.ListReportServersInDatabase()
    [void]$configSet.ListReservedUrls()

    $inst = Get-CimInstance -Namespace 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14' -Class MSReportServer_Instance -ComputerName localhost

    #$inst.GetReportServerUrls()
}