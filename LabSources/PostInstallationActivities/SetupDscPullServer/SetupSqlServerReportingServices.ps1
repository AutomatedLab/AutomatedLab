function Get-ConfigSet
{
    return Get-CimInstance -Namespace 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin' -Class MSReportServer_ConfigurationSetting
}

$configSet = Get-ConfigSet

try
{
    [Microsoft.SqlServer.Management.Common.ServerConnection]
}
catch
{
    if (Get-Module -List SqlServer) 
    {
        Import-Module SqlServer
    }
    else
    {
        Import-Module SqlPs
    }
}

if (-not $configSet.IsInitialized)
{
    # Get the ReportServer and ReportServerTempDB creation script
    $dbScript = ($configSet | Invoke-CimMethod -MethodName GenerateDatabaseCreationScript -Arguments @{DatabaseName = 'ReportServer'; Lcid = 1033; IsSharepointMode = $false }).Script

    $conn = New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList ($env:ComputerName)
    $conn.ApplicationName = 'SCOB Script'
    $conn.StatementTimeout = 0
    $conn.Connect()
    $smo = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList ($conn)

    # Create the ReportServer and ReportServerTempDB databases
    $db = $smo.Databases['master']
    [void]$db.ExecuteNonQuery($dbScript)

    # Set permissions for the databases
    $dbScript = ($configSet | Invoke-CimMethod -MethodName GenerateDatabaseRightsScript -Arguments @{UserName = $configSet.WindowsServiceIdentityConfigured; DatabaseName = 'ReportServer'; IsRemote = $false; IsWindowsUser = $true }).Script
    [void]$db.ExecuteNonQuery($dbScript)

    # Set the database connection info
    [void]($configSet | Invoke-CimMethod -MethodName SetDatabaseConnection -Arguments @{Server = '(local)'; DatabaseName = 'ReportServer'; CredentialsType = 2; UserName = ''; Password = '' })

    [void]($configSet | Invoke-CimMethod -MethodName SetVirtualDirectory -Arguments @{Application = 'ReportServerWebService'; VirtualDirectory = 'ReportServer'; Lcid = 1033 })
    [void]($configSet | Invoke-CimMethod -MethodName ReserveURL -Arguments @{Application = 'ReportServerWebService'; UrlString = 'http://+:80'; Lcid = 1033 })

    [void]($configSet | Invoke-CimMethod -MethodName SetVirtualDirectory -Arguments @{Application = 'ReportServerWebApp'; VirtualDirectory = 'Reports'; Lcid = 1033 })
    [void]($configSet | Invoke-CimMethod -MethodName ReserveURL -Arguments @{Application = 'ReportServerWebApp'; UrlString = 'http://+:80'; Lcid = 1033 })

    [void]($configSet | Invoke-CimMethod -MethodName InitializeReportServer -Arguments @{InstallationID = $configSet.InstallationID })

    # Re-start services
    [void]($configSet | Invoke-CimMethod -MethodName SetServiceState -Arguments @{EnableWindowsService = $false; EnableWebService = $false; EnableReportManager = $false })
    Restart-Service -InputObject $configSet.ServiceName
    [void]($configSet | Invoke-CimMethod -MethodName SetServiceState -Arguments @{EnableWindowsService = $true; EnableWebService = $true; EnableReportManager = $true })

    # Update the current configuration
    $configSet = Get-ConfigSet

    [void]$configSet.IsReportManagerEnabled
    [void]$configSet.IsInitialized
    [void]$configSet.IsWebServiceEnabled
    [void]$configSet.IsWindowsServiceEnabled
    [void]$configSet | Invoke-CimMethod -MethodName ListReportServersInDatabase
    [void]$configSet | Invoke-CimMethod -MethodName ListReservedUrls

    $inst = Get-CimInstance -Namespace 'root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14' -Class MSReportServer_Instance -ComputerName localhost

    #($inst | Invoke-CimMethod -Method GetReportServerUrls).URLs
}