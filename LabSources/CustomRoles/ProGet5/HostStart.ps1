param(
    [Parameter(Mandatory)]
    [string]$ProGetDownloadLink,

    [Parameter(Mandatory)]
    [string]$SqlServer,

    [Parameter(Mandatory)]
    [string]$ComputerName
)

Import-Lab -Name $data.Name -NoValidation -NoDisplay
$proGetServer = Get-LabVM -ComputerName $ComputerName
$flatDomainName = $proGetServer.DomainName.Split('.')[0]

if (-not (Get-LabVM -ComputerName $SqlServer | Where-Object { $_.Roles.Name -like 'SQLServer*' }))
{
    Write-Error "The SQL Server '$SqlServer' could not be found in the lab. ProGet cannot be installed."
    return
}

$installedDotnetVersion = Get-LabVMDotNetFrameworkVersion -ComputerName $proGetServer -NoDisplay
if (-not ($installedDotnetVersion | Where-Object Version -GT 4.5))
{
    Write-ScreenInfo "Installing .net Framework 4.5.2 on '$proGetServer'" -NoNewLine
    $net452Link = Get-LabConfigurationItem -Name dotnet452DownloadLink
    $dotnet452Installer = Get-LabInternetFile -Uri $net452Link -Path $labSources\SoftwarePackages -PassThru
    Install-LabSoftwarePackage -Path $dotnet452Installer.FullName -CommandLine '/q /log c:\dotnet452.txt' -ComputerName $proGetServer -AsScheduledJob -UseShellExecute -AsJob -NoDisplay
    Wait-LabVMRestart -ComputerName $proGetServer -TimeoutInMinutes 30
}
else
{
    Write-ScreenInfo ".net Versions installed on '$proGetServer' are '$($installedDotnetVersion.Version -join ', ')', skipping .net Framework 4.5.2 installation"
}

if (-not (Test-LabMachineInternetConnectivity -ComputerName $proGetServer))
{
    Write-Error "The lab is not connected to the internet. Internet connectivity is required to install ProGet. Check the configuration on the machines with the Routing role."
    return
}

Invoke-LabCommand -ActivityName 'Uninstalling the WebDAV feature' -ScriptBlock {
    Uninstall-WindowsFeature -Name Web-DAV-Publishing
} -ComputerName $proGetServer #https://github.com/NuGet/NuGetGallery/issues/514

Invoke-LabCommand -ActivityName 'Removing Default Web Page' -ScriptBlock {
    Get-Website -Name 'Default Web Site' | Remove-Website
} -ComputerName $proGetServer

#download ProGet
$proGetSetupFile = Get-LabInternetFile -Uri $ProGetDownloadLink -Path $labSources\SoftwarePackages -PassThru

$emailAddressPart1 = (1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join ''
$emailAddressPart2 = (1..10 | ForEach-Object { [char[]](97..122) | Get-Random }) -join ''
$installArgs = '/Edition=Trial /EmailAddress={0}@{1}.com /FullName={0} /ConnectionString="Data Source={2}; Initial Catalog=ProGet; Integrated Security=True;" /UseIntegratedWebServer=false /ConfigureIIS /Port=80 /LogFile=C:\ProGetInstallation.log /S'
$installArgs = $installArgs -f $emailAddressPart1, $emailAddressPart2, $SqlServer

Write-ScreenInfo "Installing ProGet on server '$proGetServer'"
Write-Verbose "Installation Agrs are: '$installArgs'"
Install-LabSoftwarePackage -ComputerName $proGetServer -Path $proGetSetupFile.FullName -CommandLine $installArgs

$sqlQuery = @'
USE [ProGet]
GO

-- Create a login for web server computer account
CREATE LOGIN [{2}\{0}$] FROM WINDOWS
GO

-- Add new login to database
CREATE USER [{0}$] FOR LOGIN [{2}\{0}$] WITH DEFAULT_SCHEMA=[dbo]
ALTER ROLE [db_datawriter] ADD MEMBER [{0}$]
ALTER ROLE [db_datareader] ADD MEMBER [{0}$]
ALTER ROLE [ProGetUser_Role] ADD MEMBER [{0}$]
GO

-- give Domain Admins the 'Administer' privilege
DECLARE @roleId int

SELECT @roleId = [Role_Id]
    FROM [ProGet].[dbo].[Roles]
    WHERE [Role_Name] = 'Administer'

INSERT INTO [ProGet].[dbo].[Privileges]
    VALUES ('Domain Admins@{1}', 'G', @roleId, NULL, 'G', 3)
GO

-- give Domain Users the 'Publish Packages' privilege
DECLARE @roleId int
SELECT @roleId = [Role_Id]
    FROM [ProGet].[dbo].[Roles]
    WHERE [Role_Name] = 'Publish Packages'

INSERT INTO [ProGet].[dbo].[Privileges]
    VALUES ('Domain Users@{1}', 'G', @roleId, NULL, 'G', 3)
GO

-- give Anonymous access the 'View & Download Packages' privilege
DECLARE @roleId int
SELECT @roleId = [Role_Id]
    FROM [ProGet].[dbo].[Roles]
    WHERE [Role_Name] = 'View & Download Packages'

INSERT INTO [ProGet].[dbo].[Privileges]
    VALUES ('Anonymous', 'U', @roleId, NULL, 'G', 3)
GO

-- Change user directory to 'Active Directory with Multiple Domains user directory'
UPDATE [ProGet].[dbo].[Configuration]
    SET [Value_Text] = 3
    WHERE [Key_Name] = 'Web.UserDirectoryId'
GO

-- add a internal PowerShell feed
INSERT INTO [dbo].[Feeds] ([Feed_Name], [Feed_Description], [Active_Indicator], [Cache_Connectors_Indicator], [DropPath_Text], [FeedPathOverride_Text], [FeedType_Name], [PackageStoreConfiguration_Xml], [LastSync_Date], [AllowUnknownLicenses_Indicator], [FeedConfiguration_Xml])
VALUES('PowerShell', 'Internal Feed', 'Y', 'Y', NULL, NULL, 'PowerShell', NULL, NULL, 'Y', '<Inedo.ProGet.Feeds.NuGet.NuGetFeedConfig Assembly="ProGetCoreEx"><Properties SymbolServerEnabled="False" StripSymbolFiles="False" StripSourceCodeInvert="False" UseLegacyVersioning="False" /></Inedo.ProGet.Feeds.NuGet.NuGetFeedConfig>')

GO
'@ -f $ComputerName, $proGetServer.DomainName, $flatDomainName

Write-ScreenInfo "Making changes to ProGet in the SQL database on '$sqlServer'..."
Invoke-LabCommand -ActivityName ConfigureProGet -ComputerName $sqlServer -ScriptBlock {
    $args[0] | Out-File C:\ProGetQuery.sql

    #for some reason the user is added to the ProGet database when this is only invoked once
    sqlcmd.exe -i C:\ProGetQuery.sql | Out-Null
} -ArgumentList $sqlQuery -PassThru -ErrorAction SilentlyContinue

Write-ScreenInfo "Restarting '$proGetServer'" -NoNewLine
Restart-LabVM -ComputerName $proGetServer -Wait

$isActivated = $false
$activationRetries = 10
while (-not $isActivated -and $activationRetries -gt 0)
{
    Write-ScreenInfo 'ProGet is not activated yet, retrying...'
    $isActivated = Invoke-LabCommand -ActivityName 'Verifying ProGet activation' -ComputerName $sqlServer -ScriptBlock {
        $cn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost;Database=ProGet;Trusted_Connection=True;")
        $cn.Open() | Out-Null

        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.CommandText = "SELECT * FROM [dbo].[Configuration] WHERE [Key_Name] = 'Licensing.ActivationCode'"
        $cmd.Connection = $cn

        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $adapter.SelectCommand = $cmd
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null

        $cn.Close() | Out-Null

        [bool]$dataset.Tables[0].Rows.Count
    } -PassThru -NoDisplay

    Invoke-LabCommand -ActivityName 'Trigger ProGet Activation' -ComputerName $proGetServer -ScriptBlock {
        Restart-Service -Name INEDOPROGETSVC
        iisreset.exe | Out-Null

        Start-Sleep -Seconds 30
        Invoke-WebRequest -Uri http://localhost:80 -UseBasicParsing
        Start-Sleep -Seconds 30

    } -NoDisplay

    $activationRetries--
}

if (-not $isActivated)
{
    Write-Error "'Activating ProGet did not work. Please do this manually using the web portal and then invoke the activity  'RegisterPSRepository'"
    return
}
else
{
    Write-ScreenInfo 'ProGet was successfully activated'
}

Write-ScreenInfo 'ProGet installation finished'
