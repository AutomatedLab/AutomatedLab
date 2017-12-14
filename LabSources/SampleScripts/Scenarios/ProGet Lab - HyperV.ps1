$labName = 'ProGet'
$proGetLink = 'http://inedo.com/proget/download/nosql/4.7.11'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------


New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.110.0/24
Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.110.10'
    'Add-LabMachineDefinition:Gateway' = '192.168.110.50'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

#DC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name PGDC1 -Memory 512MB -Roles RootDC -IpAddress 192.168.110.10 -PostInstallationActivity $postInstallActivity

#router
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.110.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
Add-LabMachineDefinition -Name PGRouter -Memory 512MB -Roles Routing -NetworkAdapter $netAdapter

#web server
Add-LabMachineDefinition -Name PGWeb1 -Memory 1GB -Roles WebServer -IpAddress 192.168.110.51


#SQL server
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso
Add-LabMachineDefinition -Name PGSql1 -Memory 2GB -Roles SQLServer2014 -IpAddress 192.168.110.52

#client
Add-LabMachineDefinition -Name PGClient1 -Memory 2GB -OperatingSystem 'Windows 10 Pro' -IpAddress 192.168.110.54

Install-Lab

#Install software to all lab machines
$machines = Get-LabMachine
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\ClassicShell.exe -CommandLine '/quiet ADDLOCAL=ClassicStartMenu' -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Show-LabDeploymentSummary -Detailed

#region ProGet Installation
Checkpoint-LabVM -All -SnapshotName 'Before ProGetInstallation'

$webServer = Get-LabMachine -Role WebServer | Select-Object -First 1
$sqlServer = Get-LabMachine -Role SQLServer2014, SQLServer2012 | Select-Object -First 1
$client = Get-LabMachine | Where-Object { $_.OperatingSystem.Version.Major -eq 10 }

$flatDomainName = $webServer.DomainName.Substring(0, $webServer.DomainName.IndexOf('.'))

$installPath = "$labSources\SoftwarePackages\ProGetSetup.exe"
$installArgs = '/Edition=Trial /EmailAddress=test@test.com /FullName=Test /ConnectionString="Data Source={0}; Initial Catalog=ProGet; Integrated Security=True;" /UseIntegratedWebServer=false /ConfigureIIS /LogFile=C:\ProGetInstallation.log /S'
$installArgs = $installArgs -f $sqlServer

Write-Host "Installing ProGet on server '$webServer'"
Write-Verbose "Installation Agrs are: '$installArgs'"

if (-not (Test-LabMachineInternetConnectivity -ComputerName (Get-LabMachine -Role Routing)))
{
    Write-Error "The lab is not connected to the internet. Internet connectivity is required to install ProGet. Check the configuration on the machines with the Routing role."
    return
}

Invoke-LabCommand -ActivityName 'Uninstalling the WebDAV feature' -ScriptBlock {
    Uninstall-WindowsFeature -Name Web-DAV-Publishing
} -ComputerName $webServer #https://github.com/NuGet/NuGetGallery/issues/514

#download ProGet
if (-not (Test-Path -Path $labSources\SoftwarePackages\ProGetSetup.exe))
{
    Write-Host "ProGetSetup.exe not found, downloading it from '$proGetLink' to '$installPath'"
    Invoke-WebRequest -Uri $proGetLink -OutFile $installPath
}

Install-LabSoftwarePackage -ComputerName $webServer -Path $installPath -CommandLine $installArgs

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

--INSERT INTO [ProGet].[dbo].[Configuration] 
--VALUES ('Web.InvalidatePrivilegesCachedBeforeDate', '2016-05-31T12:37:00.7751728Z')

-- Change user directory to 'Active Directory with Multiple Domains user directory'
UPDATE [ProGet].[dbo].[Configuration]
    SET [Value_Text] = 3
    WHERE [Key_Name] = 'Web.UserDirectoryId'
GO

-- add a internal PowerShell feed
INSERT INTO [dbo].[Feeds] ([Feed_Name] ,[Feed_Description],[Active_Indicator],[Cache_Connectors_Indicator],[DropPath_Text],[FeedPathOverride_Text],
[FeedType_Name],[PackageStoreConfiguration_Xml],[SyncToken_Bytes],[SyncTarget_Url],[LastSync_Date],[AllowUnknownLicenses_Indicator])
VALUES('Internal','Sample Feed','Y','Y',null,null,'PowerShell',null,null,null,null,'Y')

GO
'@ -f $webServer, $webServer.DomainName, $flatDomainName

Write-Host "Making changes to ProGet in the SQL database on '$sqlServer'..."
Invoke-LabCommand -ActivityName ConfigureProGet -ComputerName $sqlServer -ScriptBlock {
    $args[0] | Out-File C:\ProGetQuery.sql

    #for some reason the user is added to the ProGet database when this is only invoked once
    sqlcmd.exe -i C:\ProGetQuery.sql | Out-Null
} -ArgumentList $sqlQuery -PassThru -ErrorAction SilentlyContinue

Write-Host "Restarting '$webServer'"
Restart-LabVM -ComputerName $webServer -Wait

$isActivated = $false
$activationRetries = 5
while (-not $isActivated -and $activationRetries -gt 0)
{
    Write-Host 'ProGet is not activated yet, retrying...'
    $isActivated = Invoke-LabCommand -ActivityName TriggerProGetActivation -ComputerName $webServer -ScriptBlock {
        Restart-Service -Name INEDOPROGETSVC
        iisreset.exe | Out-Null

        Start-Sleep -Seconds 30

        try
        {
            $result = -not [bool]((Invoke-WebRequest -Uri 'http://localhost:81/feeds/Default').Links | Where-Object href -like *licensing*)
        }
        catch
        { }
        $result
    } -PassThru

    $activationRetries--
}

if (-not $isActivated)
{
    Write-Error "'Activating ProGet did not work. Please do this manually using the web portal and then invoke the activity  'RegisterPSRepository'"
    return
}

Restart-LabVM -ComputerName $webServer -Wait

Write-Host 'ProGet is now activated'

Invoke-LabCommand -ActivityName RegisterPSRepository -ComputerName $client -ScriptBlock {
    Install-PackageProvider -Name NuGet -Force

    $targetPath = 'C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet'
    if (-not (Test-Path -Path $targetPath))
    {
        mkdir -Path $targetPath -Force | Out-Null
    }

    $sourceNugetExe = 'http://nuget.org/NuGet.exe'
    $targetNugetExe = Join-Path -Path $targetPath -ChildPath NuGet.exe
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
    
    $path = "http://$($args[0]):81/nuget/Internal"
    Register-PSRepository -Name Internal -SourceLocation $path -PublishLocation $path -InstallationPolicy Trusted

    #--------------------------------------------------------------------------------

    (New-ScriptFileInfo -Path C:\SomeScript2.ps1 -Version 1.0 -Author Me -Description Test -PassThru -Force) + 'Get-Date' | Out-File C:\SomeScript.ps1
    Publish-Script -Path C:\SomeScript.ps1 -Repository Internal -NuGetApiKey 'Install@Contoso.com:Somepass1'

} -ArgumentList $webServer
#endregion ProGet Installation