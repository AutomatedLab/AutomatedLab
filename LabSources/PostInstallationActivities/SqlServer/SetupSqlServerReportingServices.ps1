function Get-ConfigSet
{
    $class = Get-WmiObject -List -Namespace root\microsoft -Class MSReportServer_ConfigurationSetting -Recurse
    Get-CimInstance -Namespace $class.__NAMESPACE -Class $class.Name

    if ($class.__NAMESPACE -match '\\v(?<version>\d\d)\\*.')
    {
        $version = $Matches.version
        Write-Verbose "Installed SSRS version is $version"
    }
}

function Get-Instance
{
    $class = Get-WmiObject -List -Namespace root\microsoft -Class MSReportServer_Instance -Recurse
    $instance = Get-CimInstance -Namespace $class.__NAMESPACE -Class $class.Name
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
    $configSet | Invoke-CimMethod -MethodName ListReportServersInDatabase | Out-Null
    $configSet | Invoke-CimMethod -MethodName ListReservedUrls | Out-Null

    $instance = Get-Instance

    Write-Verbose 'Reporting Services are now configured. The URLs to access the reporting services are:'
    foreach ($url in ($instance | Invoke-CimMethod -Method GetReportServerUrls).URLs)
    {
        Write-Verbose "`t$url"
    }
}
