param (
	[Parameter(Mandatory)]
	[string]$DomainAndComputerName
)

$creatreDbQuery = @'
CREATE DATABASE [DSC]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'DSC', FILENAME = N'C:\DSCDB\DSC.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON
( NAME = N'DSC_log', FILENAME = N'C:\DSCDB\DSC_log.ldf' , SIZE = 1024KB , MAXSIZE = 1024GB , FILEGROWTH = 10%)
GO

ALTER DATABASE DSC SET RECOVERY SIMPLE
GO

ALTER DATABASE [DSC] SET COMPATIBILITY_LEVEL = 130
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DSC].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [DSC] SET ANSI_NULL_DEFAULT OFF
GO

ALTER DATABASE [DSC] SET ANSI_NULLS OFF
GO

ALTER DATABASE [DSC] SET ANSI_PADDING OFF
GO

ALTER DATABASE [DSC] SET ANSI_WARNINGS OFF
GO

ALTER DATABASE [DSC] SET ARITHABORT OFF
GO

ALTER DATABASE [DSC] SET AUTO_CLOSE OFF
GO

ALTER DATABASE [DSC] SET AUTO_SHRINK OFF
GO

ALTER DATABASE [DSC] SET AUTO_UPDATE_STATISTICS ON
GO

ALTER DATABASE [DSC] SET CURSOR_CLOSE_ON_COMMIT OFF
GO

ALTER DATABASE [DSC] SET CURSOR_DEFAULT  GLOBAL
GO

ALTER DATABASE [DSC] SET CONCAT_NULL_YIELDS_NULL OFF
GO

ALTER DATABASE [DSC] SET NUMERIC_ROUNDABORT OFF
GO

ALTER DATABASE [DSC] SET QUOTED_IDENTIFIER OFF
GO

ALTER DATABASE [DSC] SET RECURSIVE_TRIGGERS OFF
GO

ALTER DATABASE [DSC] SET  DISABLE_BROKER
GO

ALTER DATABASE [DSC] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO

ALTER DATABASE [DSC] SET DATE_CORRELATION_OPTIMIZATION OFF
GO

ALTER DATABASE [DSC] SET TRUSTWORTHY OFF
GO

ALTER DATABASE [DSC] SET ALLOW_SNAPSHOT_ISOLATION OFF
GO

ALTER DATABASE [DSC] SET PARAMETERIZATION SIMPLE
GO

ALTER DATABASE [DSC] SET READ_COMMITTED_SNAPSHOT OFF
GO

ALTER DATABASE [DSC] SET HONOR_BROKER_PRIORITY OFF
GO

ALTER DATABASE [DSC] SET RECOVERY SIMPLE
GO

ALTER DATABASE [DSC] SET  MULTI_USER
GO

ALTER DATABASE [DSC] SET PAGE_VERIFY CHECKSUM
GO

ALTER DATABASE [DSC] SET DB_CHAINING OFF
GO

ALTER DATABASE [DSC] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF )
GO

ALTER DATABASE [DSC] SET TARGET_RECOVERY_TIME = 0 SECONDS
GO

ALTER DATABASE [DSC] SET DELAYED_DURABILITY = DISABLED
GO

ALTER DATABASE [DSC] SET  READ_WRITE
GO

USE [DSC]

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Devices](
    [TargetName] [nvarchar](255) NOT NULL,
    [ConfigurationID] [nvarchar](255) NOT NULL,
    [ServerCheckSum] [nvarchar](255) NOT NULL,
    [TargetCheckSum] [nvarchar](255) NOT NULL,
    [NodeCompliant] [bit] NOT NULL,
    [LastComplianceTime] [datetime] NULL,
    [LastHeartbeatTime] [datetime] NULL,
    [Dirty] [bit] NOT NULL,
    [StatusCode] [int] NULL,
 CONSTRAINT [PK_Devices] PRIMARY KEY CLUSTERED
(
    [TargetName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[RegistrationData](
    [AgentId] [nvarchar](255) NOT NULL,
    [LCMVersion] [nvarchar](255) NULL,
    [NodeName] [nvarchar](255) NULL,
    [IPAddress] [nvarchar](255) NULL,
    [ConfigurationNames] [nvarchar](max) NULL,
 CONSTRAINT [PK_RegistrationData] PRIMARY KEY CLUSTERED
(
    [AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

CREATE TABLE [dbo].[StatusReport](
    [JobId] [nvarchar](50) NOT NULL,
    [Id] [nvarchar](50) NOT NULL,
    [OperationType] [nvarchar](255) NULL,
    [RefreshMode] [nvarchar](255) NULL,
    [Status] [nvarchar](255) NULL,
    [LCMVersion] [nvarchar](50) NULL,
    [ReportFormatVersion] [nvarchar](255) NULL,
    [ConfigurationVersion] [nvarchar](255) NULL,
    [NodeName] [nvarchar](255) NULL,
    [IPAddress] [nvarchar](255) NULL,
    [StartTime] [datetime] NULL,
    [EndTime] [datetime] NULL,
    [Errors] [nvarchar](max) NULL,
    [StatusData] [nvarchar](max) NULL,
    [RebootRequested] [nvarchar](255) NULL,
    [AdditionalData] [nvarchar](max) NULL,
 CONSTRAINT [PK_StatusReport] PRIMARY KEY CLUSTERED
(
    [JobId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[RegistrationMetaData](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AgentId] [nvarchar](255) NOT NULL,
	[CreationTime] [datetime] NOT NULL
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[StatusReportMetaData](
       [Id] [int] IDENTITY(1,1) NOT NULL,
       [JobId] [nvarchar](255) NOT NULL,
       [CreationTime] [datetime] NOT NULL
) ON [PRIMARY]

GO

CREATE TRIGGER [dbo].[InsertCreationTimeRDMD]
ON [dbo].[RegistrationData]
AFTER INSERT
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
  SET NOCOUNT ON;

  -- get the last id value of the record inserted or updated
  DECLARE @AgentId nvarchar(255)
  SELECT @AgentId = AgentId
  FROM INSERTED

  -- Insert statements for trigger here
  INSERT INTO [RegistrationMetaData] (AgentId,CreationTime)
  VALUES(@AgentId,GETDATE())

END
GO

CREATE TRIGGER [dbo].[InsertCreationTimeSRMD]
ON [dbo].[StatusReport]
AFTER INSERT
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
  SET NOCOUNT ON;

  -- get the last id value of the record inserted or updated
  DECLARE @JobId nvarchar(255)
  SELECT @JobId = JobId
  FROM INSERTED

  -- Insert statements for trigger here
  INSERT INTO [StatusReportMetaData] (JobId,CreationTime)
  VALUES(@JobId,GETDATE())

END
GO

ALTER TABLE [dbo].[StatusReport] ENABLE TRIGGER [InsertCreationTimeSRMD]
ALTER TABLE [dbo].[RegistrationData] ENABLE TRIGGER [InsertCreationTimeRDMD]
GO

--Base views
CREATE VIEW [dbo].[vBaseNodeUpdateErrors]
AS
WITH CTE(NodeName
	,CreationTime
	,StartTime
	,EndTime
	,ErrorMessage
) AS (
SELECT RegistrationData.NodeName
	,CreationTime
	,StartTime
	,EndTime
	,(SELECT [ResourceId] + ':' + ' (' + [ErrorCode] + ') ' + [ErrorMessage] + ',' AS [text()]
		FROM OPENJSON(
			(SELECT TOP 1  [value] FROM OPENJSON([Errors]))
		)
		WITH (
			ErrorMessage nvarchar(2000) '$.ErrorMessage',
			ErrorCode nvarchar(20) '$.ErrorCode',
			ResourceId nvarchar(200) '$.ResourceId'
		) FOR XML PATH ('')) AS ErrorMessage
	FROM StatusReport
	INNER JOIN RegistrationData ON StatusReport.Id = RegistrationData.AgentId
	INNER JOIN StatusReportMetaData AS SRMD ON StatusReport.JobId = SRMD.JobId
)
SELECT TOP 5000 * FROM CTE WHERE
ErrorMessage IS NOT NULL
--ErrorMessage LIKE '%cannot find module%'
--OR ErrorMessage LIKE '%The assigned configuration%is not found%'
--OR ErrorMessage LIKE '%Checksum file not located for%'
--OR ErrorMessage LIKE '%Checksum for module%'
ORDER BY EndTime DESC

--Module does not exist					Cannot find module
--Configuration does not exist			The assigned configuration <Name> is not found
--Checksum does not exist				Checksum file not located for
GO

CREATE VIEW [dbo].[vBaseNodeLocalStatus]
AS

WITH CTE(JobId
	,NodeName
	,OperationType
	,RefreshMode
	,[Status]
	,LCMVersion
	,ReportFormatVersion
	,ConfigurationVersion
	,IPAddress
	,CreationTime
	,StartTime
	,EndTime
	,Errors
	,StatusData
	,RebootRequested
	,AdditionalData
	,ErrorMessage
) AS (
SELECT StatusReport.JobId
	,RegistrationData.NodeName
	,OperationType
	,RefreshMode
	,[Status]
	,StatusReport.LCMVersion
	,ReportFormatVersion
	,ConfigurationVersion
	,StatusReport.IPAddress
	,CreationTime
	,StartTime
	,EndTime
	,Errors
	,StatusData
	,RebootRequested
	,AdditionalData
	,(SELECT [ResourceId] + ':' + ' (' + [ErrorCode] + ') ' + [ErrorMessage] + ',' AS [text()]
	FROM OPENJSON(
		(SELECT TOP 1  [value] FROM OPENJSON([Errors]))
	)
	WITH (
		ErrorMessage nvarchar(2000) '$.ErrorMessage',
		ErrorCode nvarchar(20) '$.ErrorCode',
		ResourceId nvarchar(200) '$.ResourceId'
		) FOR XML PATH ('')
	) AS ErrorMessage
	FROM StatusReport
	INNER JOIN RegistrationData ON StatusReport.Id = RegistrationData.AgentId
	INNER JOIN StatusReportMetaData AS SRMD ON StatusReport.JobId = SRMD.JobId
	)
	SELECT * FROM CTE
	WHERE
		ErrorMessage NOT LIKE '%cannot find module%'
		AND ErrorMessage NOT LIKE '%The assigned configuration%is not found%'
		AND ErrorMessage NOT LIKE '%Checksum file not located for%'
		AND ErrorMessage NOT LIKE '%Checksum for module%'
		AND [Status] IS NOT NULL
		OR ErrorMessage IS NULL

GO

--Adding functions
CREATE FUNCTION [dbo].[Split] (
      @InputString                  VARCHAR(8000),
      @Delimiter                    VARCHAR(50)
)

RETURNS @Items TABLE (
      Item                          VARCHAR(8000)
)

AS
BEGIN
      IF @Delimiter = ' '
      BEGIN
            SET @Delimiter = ','
            SET @InputString = REPLACE(@InputString, ' ', @Delimiter)
      END

      IF (@Delimiter IS NULL OR @Delimiter = '')
            SET @Delimiter = ','

      DECLARE @Item           VARCHAR(8000)
      DECLARE @ItemList       VARCHAR(8000)
      DECLARE @DelimIndex     INT

      SET @ItemList = @InputString
      SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)
      WHILE (@DelimIndex != 0)
      BEGIN
            SET @Item = SUBSTRING(@ItemList, 0, @DelimIndex)
            INSERT INTO @Items VALUES (@Item)

            -- Set @ItemList = @ItemList minus one less item
            SET @ItemList = SUBSTRING(@ItemList, @DelimIndex+1, LEN(@ItemList)-@DelimIndex)
            SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)
      END -- End WHILE

      IF @Item IS NOT NULL -- At least one delimiter was encountered in @InputString
      BEGIN
            SET @Item = @ItemList
            INSERT INTO @Items VALUES (@Item)
      END

      -- No delimiters were encountered in @InputString, so just return @InputString
      ELSE INSERT INTO @Items VALUES (@InputString)

      RETURN

END -- End Function
GO

CREATE FUNCTION [dbo].[tvfGetRegistrationData] ()
RETURNS TABLE
    AS
RETURN
(
    SELECT NodeName, AgentId,
        (SELECT TOP (1) Item FROM dbo.Split(dbo.RegistrationData.IPAddress, ';') AS IpAddresses) AS IP,
        (SELECT(SELECT [Value] + ',' AS [text()] FROM OPENJSON([ConfigurationNames]) FOR XML PATH (''))) AS ConfigurationName,
        (SELECT COUNT(*) FROM (SELECT [Value] FROM OPENJSON([ConfigurationNames]))AS ConfigurationCount ) AS ConfigurationCount
    FROM dbo.RegistrationData
)
GO

CREATE FUNCTION [dbo].[tvfGetNodeStatus] ()
RETURNS TABLE
    AS
RETURN
(
    SELECT vBaseNodeLocalStatus.NodeName
	,[Status]
	,CreationTime AS [Time]
	,RebootRequested
	,OperationType
	,JobId

	,(
	SELECT [HostName] FROM OPENJSON(
		(SELECT [value] FROM OPENJSON([StatusData]))
	) WITH (HostName nvarchar(200) '$.HostName')) AS HostName

	,(
	SELECT [ResourceId] + ',' AS [text()]
	FROM OPENJSON(
	(SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
	)
	WITH (
		ResourceId nvarchar(200) '$.ResourceId'
	) FOR XML PATH ('')) AS ResourcesInDesiredState

	,(
	SELECT [ResourceId] + ',' AS [text()]
	FROM OPENJSON(
	(SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesNotInDesiredState')
	)
	WITH (
		ResourceId nvarchar(200) '$.ResourceId'
	) FOR XML PATH ('')) AS ResourcesNotInDesiredState

	,(
	SELECT SUM(CAST(REPLACE(DurationInSeconds, ',', '.') AS float)) AS Duration
	FROM OPENJSON(
	(SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
	)
	WITH (
			DurationInSeconds nvarchar(50) '$.DurationInSeconds',
			InDesiredState bit '$.InDesiredState'
		)
	) AS Duration

	,(
	SELECT [DurationInSeconds] FROM OPENJSON(
		(SELECT [value] FROM OPENJSON([StatusData]))
	) WITH (DurationInSeconds nvarchar(200) '$.DurationInSeconds')) AS DurationWithOverhead

	,(
	SELECT COUNT(*)
	FROM OPENJSON(
	(SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
	)) AS ResourceCountInDesiredState

	,(
	SELECT COUNT(*)
	FROM OPENJSON(
	(SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesNotInDesiredState')
	)) AS ResourceCountNotInDesiredState

	,(
	SELECT [ResourceId] + ':' + ' (' + [ErrorCode] + ') ' + [ErrorMessage] + ',' AS [text()]
	FROM OPENJSON(
	(SELECT TOP 1 [value] FROM OPENJSON([Errors]))
	)
	WITH (
		ErrorMessage nvarchar(2000) '$.ErrorMessage',
		ErrorCode nvarchar(20) '$.ErrorCode',
		ResourceId nvarchar(200) '$.ResourceId'
	) FOR XML PATH ('')) AS ErrorMessage

	,(
	SELECT [value] FROM OPENJSON([StatusData])
	) AS RawStatusData

	,(
	SELECT [value] FROM OPENJSON([Errors]) FOR JSON PATH
	) AS RawErrors

	FROM dbo.vBaseNodeLocalStatus
	INNER JOIN (
		SELECT NodeName
		,MAX(CreationTime) AS MaxEndTime
		FROM dbo.vBaseNodeLocalStatus
		WHERE OperationType <> 'LocalConfigurationManager'
		GROUP BY NodeName

	) AS SubMax ON CreationTime = SubMax.MaxEndTime AND [dbo].[vBaseNodeLocalStatus].[NodeName] = SubMax.NodeName
)
GO

--Remaining views
CREATE VIEW [dbo].[vRegistrationData]
AS
SELECT GetRegistrationData.*
FROM dbo.tvfGetRegistrationData() AS GetRegistrationData
GO

CREATE VIEW [dbo].[vNodeStatusSimple]
AS
SELECT rd.NodeName, IIF(nss.NodeName IS NULL,'Failure',nss.Status) as Status, nss.Time
FROM (
SELECT DISTINCT dbo.StatusReport.NodeName, dbo.StatusReport.Status, dbo.StatusReport.EndTime AS Time
FROM dbo.StatusReport INNER JOIN
    (SELECT MAX(EndTime) AS MaxEndTime, NodeName
    FROM dbo.StatusReport AS StatusReport_1
    GROUP BY NodeName) AS SubMax ON dbo.StatusReport.EndTime = SubMax.MaxEndTime AND dbo.StatusReport.NodeName = SubMax.NodeName
       WHERE dbo.StatusReport.Status IS NOT NULL
) as nss
RIGHT OUTER JOIN dbo.RegistrationData AS rd
ON nss.NodeName = rd.NodeName

GO


CREATE VIEW [dbo].[vNodeStatusComplex]
AS
SELECT GetNodeStatus.*,
IIF([ResourceCountNotInDesiredState] > 0 OR [ResourceCountInDesiredState] = 0, 'FALSE', 'TRUE') AS [InDesiredState]
FROM dbo.tvfGetNodeStatus() AS GetNodeStatus
GO
CREATE VIEW [dbo].[vNodeStatusCount]
AS
SELECT NodeName, COUNT(*) AS NodeStatusCount
FROM dbo.StatusReport
WHERE (NodeName IS NOT NULL)
GROUP BY NodeName
GO

CREATE VIEW [dbo].[vStatusReportDataNewest]
AS
SELECT TOP (1000) dbo.StatusReport.JobId,dbo.RegistrationData.NodeName, dbo.StatusReport.OperationType, dbo.StatusReport.RefreshMode, dbo.StatusReport.Status, dbo.StatusReportMetaData.CreationTime,
dbo.StatusReport.StartTime, dbo.StatusReport.EndTime, dbo.StatusReport.Errors, dbo.StatusReport.StatusData
FROM dbo.StatusReport
INNER JOIN dbo.StatusReportMetaData ON dbo.StatusReport.JobId = dbo.StatusReportMetaData.JobId
INNER JOIN dbo.RegistrationData ON dbo.StatusReport.Id = dbo.RegistrationData.AgentId
ORDER BY dbo.StatusReportMetaData.CreationTime DESC
GO
'@

$addPermissionsQuery = @'
-- Adding Permissions
USE [master]
GO

CREATE LOGIN [{0}\{1}] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

USE [DSC]

CREATE USER [{1}] FOR LOGIN [{0}\{1}] WITH DEFAULT_SCHEMA=[db_datareader]
GO

ALTER ROLE [db_datareader] ADD MEMBER [{1}]
GO

ALTER ROLE [db_datawriter] ADD MEMBER [{1}]
GO
'@

if (-not (Test-Path -Path C:\DSCDB))
{
	New-Item -ItemType Directory -Path C:\DSCDB | Out-Null
}

$dbCreated = Invoke-Sqlcmd -Query "SELECT name FROM master.sys.databases WHERE name='DSC'" -ServerInstance localhost
if (-not $dbCreated)
{
	Write-Verbose "Creating the DSC database on the local default SQL instance..."

	Invoke-Sqlcmd -Query $creatreDbQuery -ServerInstance localhost

	Write-Verbose 'finished.'
	Write-Verbose 'Database is stored on C:\DSCDB'
}

Write-Verbose "Adding permissions to DSC database for $DomainAndComputerName..."

$domain = ($DomainAndComputerName -split '\\')[0]
$name = ($DomainAndComputerName -split '\\')[1]

if ($ComputerName -eq $env:COMPUTERNAME -and $DomainName -eq $env:USERDOMAIN)
{
	$domain = 'NT AUTHORITY'
	$name = 'SYSTEM'
}
$name = $name + '$'

$account = New-Object System.Security.Principal.NTAccount($domain, $name)
try
{
	$account.Translate([System.Security.Principal.SecurityIdentifier]) | Out-Null
}
catch
{
	Write-Error "The account '$domain\$name' could not be found"
	continue
}

$query = $addPermissionsQuery -f $domain, $name

Invoke-Sqlcmd -Query $query -ServerInstance localhost

Write-Verbose 'finished'
