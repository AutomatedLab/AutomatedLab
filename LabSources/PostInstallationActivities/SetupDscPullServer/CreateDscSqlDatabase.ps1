param (
	[Parameter(Mandatory)]
	[string]
	$DomainAndComputerName,

	[bool]
	$UseNwFeature = $false
)

[string]$createDbQuery = @'
USE [master]
GO
/****** Object:  Database [DSC]    Script Date: 07.04.2021 16:59:54 ******/

DECLARE @DefaultDataPath varchar(max)
SET @DefaultDataPath = (SELECT CONVERT(varchar(max), SERVERPROPERTY('INSTANCEDEFAULTDATAPATH')))

DECLARE @DefaultLogPath varchar(max)
SET @DefaultLogPath = (SELECT CONVERT(varchar(max), SERVERPROPERTY('INSTANCEDEFAULTLOGPATH')))

EXECUTE('
CREATE DATABASE [DSC]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N''DSC'', FILENAME = ''' + @DefaultDataPath + 'DSC.mdf'', SIZE = 16384KB, MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB )
 LOG ON
( NAME = N''DSC_log'', FILENAME = ''' + @DefaultLogPath + 'DSC_log.mdf'', SIZE = 2048KB, MAXSIZE = 2048GB, FILEGROWTH = 16384KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
');
GO

ALTER DATABASE [DSC] SET RECOVERY SIMPLE
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
EXEC sys.sp_db_vardecimal_storage_format N'DSC', N'ON'
GO
ALTER DATABASE [DSC] SET QUERY_STORE = OFF
GO
USE [DSC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

--Adding Stored Procedures
CREATE PROCEDURE [dbo].[SetNodeEndTime]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @NodeName VARCHAR(255), @EndTime DATE
  
	DECLARE c CURSOR FOR
	SELECT NodeName, MAX(EndTime) AS EndTime FROM StatusReport GROUP BY NodeName
  
	OPEN c
  
	FETCH NEXT FROM c
	INTO @NodeName, @EndTime
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
  
	   PRINT @NodeName

	   UPDATE RegistrationData
		SET LastUpdated = @EndTime
		WHERE NodeName = @NodeName
  
	   FETCH NEXT FROM c
	   INTO @NodeName, @EndTime
	END  
  
	CLOSE c
	DEALLOCATE c

END
GO

-- ----------------------------------------------

CREATE PROCEDURE [dbo].[CleanupDscData]
	@Date Date = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @oldDate AS DATE
	DECLARE @before1900 AS DATE
	SET @oldDate = COALESCE(@Date, CONVERT(DATE, DATEADD(DAY, -180, GETDATE())))
	SET @before1900 = '1900-01-01'

    DELETE FROM [DSC].[dbo].[StatusReport] WHERE CONVERT(DATE, [StartTime]) < @oldDate OR CONVERT(DATE, [EndTime]) < @oldDate

	DELETE FROM [DSC].[dbo].[StatusReport] WHERE CONVERT(DATE, [StartTime]) < @before1900 OR CONVERT(DATE, [EndTime]) < @before1900

	DELETE FROM [DSC].[dbo].[StatusReportMetaData] WHERE CONVERT(DATE, [CreationTime]) < @oldDate

END
GO


--End Stored Procedures

/****** Object:  Table [dbo].[RegistrationData]    Script Date: 07.04.2021 16:59:54 ******/
CREATE TABLE [dbo].[RegistrationData](
	[AgentId] [nvarchar](255) NOT NULL,
	[LCMVersion] [nvarchar](255) NULL,
	[NodeName] [nvarchar](255) NULL,
	[IPAddress] [nvarchar](255) NULL,
	[ConfigurationNames] [nvarchar](max) NULL,
    [LastUpdated] [date] NULL,
 CONSTRAINT [PK_RegistrationData] PRIMARY KEY CLUSTERED 
(
    [AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[StatusReport]    Script Date: 07.04.2021 16:59:54 ******/
CREATE TABLE [dbo].[StatusReport](
    [JobId] [nvarchar](255) NOT NULL,
    [Id] [nvarchar](255) NOT NULL,
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_StatusReport_NodeNameStartTime] ON [dbo].[StatusReport]
(
	[NodeName] ASC,
	[StartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[StatusReportMetaData]    Script Date: 07.04.2021 16:59:54 ******/
CREATE TABLE [dbo].[StatusReportMetaData](
	[JobId] [nvarchar](255) NOT NULL,
	[CreationTime] [datetime] NOT NULL,
	[ResourcesInDesiredStateCount] [int] NULL,
	[ResourcesNotInDesiredStateCount] [int] NULL,
	[ResourceCount] [int] NULL,
	[NodeStatus] [nvarchar](50) NULL,
	[NodeName] [nvarchar](255) NULL,
	[ErrorMessage] [nvarchar](2500) NULL,
	[HostName] [nvarchar](50) NULL,
	[ResourcesInDesiredState] [nvarchar](max) NULL,
	[ResourcesNotInDesiredState] [nvarchar](max) NULL,
	[Duration] [float] NULL,
	[DurationWithOverhead] [float] NULL
CONSTRAINT [PK_StatusReportMetaData] PRIMARY KEY CLUSTERED 
(
    [JobId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IDX_StatusReportMetaData_NodeNameCreationTime] ON [dbo].[StatusReportMetaData]
(
	[NodeName] ASC,
	[CreationTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[TaggingData]    Script Date: 4/6/2021 10:53:28 AM ******/
CREATE TABLE [dbo].[TaggingData](
	[AgentId] [nvarchar](255) NOT NULL,
	[Environment] [nvarchar](255) NULL,
	[BuildNumber] [int] NOT NULL,
	[GitCommitId] [nvarchar](255) NULL,
	[NodeVersion] [nvarchar](50) NULL,
	[NodeRole] [nvarchar](50) NULL,
	[Version] [nvarchar](50) NOT NULL,
	[BuildDate] [datetime] NOT NULL,
	[Timestamp] [datetime] NOT NULL,
	[Layers] [nvarchar](max) NULL,
CONSTRAINT [PK_TaggingData] PRIMARY KEY CLUSTERED 
(
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Devices]    Script Date: 07.04.2021 16:59:54 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NodeErrorData]    Script Date: 4/6/2021 10:53:28 AM ******/
CREATE TABLE [dbo].[NodeErrorData](
	[NodeName] [nvarchar](50) NOT NULL,
	[StartTime] [datetime] NULL,
	[Errors] [nvarchar](max) NULL
CONSTRAINT [PK_NodeErrorData] PRIMARY KEY CLUSTERED 
(
    [NodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NodeLastStatusData]    Script Date: 4/6/2021 10:53:28 AM ******/
CREATE TABLE [dbo].[NodeLastStatusData](
	[NodeName] [nvarchar](50) NOT NULL,
	[NumberOfResources] [int] NULL,
	[DscMode] [nvarchar](10) NULL,
	[DscConfigMode] [nvarchar](100) NULL,
	[ActionAfterReboot] [nvarchar](50) NULL,
	[ReapplyMOFCycle] [int] NULL,
	[CheckForNewMOF] [int] NULL,
	[PullServer] [nvarchar](50) NULL,
	[LastUpdate] [datetime] NULL
CONSTRAINT [PK_NodeLastStatusData] PRIMARY KEY CLUSTERED 
(
    [NodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[RegistrationMetaData]    Script Date: 07.04.2021 16:59:54 ******/
CREATE TABLE [dbo].[RegistrationMetaData](
	[AgentId] [nvarchar](255) NOT NULL,
	[CreationTime] [datetime] NOT NULL
CONSTRAINT [PK_RegistrationMetaData] PRIMARY KEY CLUSTERED 
(
    [AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
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
SELECT rd.NodeName
    ,srmd.CreationTime
    ,sr.StartTime
    ,sr.EndTime
    ,srmd.ErrorMessage
    FROM StatusReport AS sr
    INNER JOIN RegistrationData AS rd ON sr.Id = rd.AgentId
    INNER JOIN StatusReportMetaData AS srmd ON sr.JobId = srmd.JobId
)
SELECT TOP 5000 * FROM CTE WHERE
ErrorMessage IS NOT NULL
--ErrorMessage LIKE '%cannot find module%'
--OR ErrorMessage LIKE '%The assigned configuration%is not found%'
--OR ErrorMessage LIKE '%Checksum file not located for%'
--OR ErrorMessage LIKE '%Checksum for module%'
ORDER BY EndTime DESC

--Module does not exist					Cannot find module
--Configuration does not exist          The assigned configuration <Name> is not found
--Checksum does not exist               Checksum file not located for
GO

/****** Object:  View [dbo].[vBaseNodeLocalStatus]    Script Date: 07.04.2021 16:59:54 ******/
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
    ,ResourceCountInDesiredState
    ,ResourceCountNotInDesiredState
    ,ResourcesInDesiredState
    ,ResourcesNotInDesiredState
    ,Duration
    ,DurationWithOverhead
    ,HostName
) AS (
SELECT sr.JobId
      ,sr.NodeName
      ,sr.OperationType
      ,sr.RefreshMode
      ,sr.Status
      ,sr.LCMVersion
      ,sr.ReportFormatVersion
      ,sr.ConfigurationVersion
      ,sr.IPAddress
      ,srmd.CreationTime
      ,sr.StartTime
      ,sr.EndTime
      ,sr.Errors
      ,sr.StatusData
      ,sr.RebootRequested
      ,sr.AdditionalData
      ,srmd.ErrorMessage
      ,srmd.ResourcesInDesiredStateCount
      ,srmd.ResourcesNotInDesiredStateCount
      ,srmd.ResourcesInDesiredState
      ,srmd.ResourcesNotInDesiredState
      ,srmd.Duration
      ,srmd.DurationWithOverhead
      ,srmd.HostName
    FROM StatusReport AS sr
    INNER JOIN RegistrationData AS rd ON sr.Id = rd.AgentId
    INNER JOIN StatusReportMetaData AS srmd ON sr.JobId = srmd.JobId
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

/****** Object:  UserDefinedFunction [dbo].[tvfGetRegistrationData]    Script Date: 07.04.2021 16:59:54 ******/
CREATE FUNCTION [dbo].[tvfGetRegistrationData] ()
RETURNS TABLE
    AS
RETURN
(
    SELECT rd.NodeName AS NodeName, 
           rd.AgentId AS AgentId,
           (SELECT TOP (1) Item FROM dbo.Split(rd.IPAddress, ';') AS IpAddresses) AS IP,
           (SELECT(SELECT [Value] + ',' AS [text()] FROM OPENJSON([ConfigurationNames]) FOR XML PATH (''))) AS ConfigurationName,
           (SELECT COUNT(*) FROM (SELECT [Value] FROM OPENJSON([ConfigurationNames]))AS ConfigurationCount ) AS ConfigurationCount,
           rdmd.CreationTime AS CreationTime
    FROM dbo.RegistrationData rd
    INNER JOIN RegistrationMetaData AS rdmd ON rd.AgentId = rdmd.AgentId
)
GO

/****** Object:  UserDefinedFunction [dbo].[tvfGetNodeStatus]    Script Date: 07.04.2021 16:59:54 ******/
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
        ,HostName
        ,ResourcesInDesiredState
        ,ResourcesNotInDesiredState
        ,Duration
        ,DurationWithOverhead
        ,ResourceCountInDesiredState
        ,ResourceCountNotInDesiredState
        ,ErrorMessage
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

/****** Object:  View [dbo].[vRegistrationData]    Script Date: 07.04.2021 16:59:54 ******/
CREATE VIEW [dbo].[vRegistrationData]
AS
SELECT GetRegistrationData.*
FROM dbo.tvfGetRegistrationData() AS GetRegistrationData
GO

/****** Object:  View [dbo].[vNodeStatusSimple]    Script Date: 07.04.2021 16:59:54 ******/
CREATE VIEW [dbo].[vNodeStatusSimple]
AS
SELECT nss.NodeName
       ,nss.StartTime
	   ,nss.NodeStatus AS Status
       ,CASE WHEN nss.EndTime < CAST('19000101' AS datetime) THEN NULL ELSE nss.EndTime END AS EndTime
       ,nss.ResourcesInDesiredStateCount AS ResourceCountInDesiredState
       ,nss.ResourcesNotInDesiredStateCount AS ResourceCountNotInDesiredState
       ,IIF(nss.ResourcesNotInDesiredState IS NULL, '', nss.ResourcesNotInDesiredState) AS ResourcesNotInDesiredState
       ,IIF(nss.ErrorMessage IS NULL, '', nss.ErrorMessage) AS ErrorMessage
       ,nss.Duration
       ,nss.DurationWithOverhead
       ,nss.RebootRequested
FROM (
	SELECT DISTINCT
		sr.JobId
		,sr.NodeName
		,sr.OperationType
		,sr.RebootRequested
		,sr.StartTime
		,sr.EndTime
		,sr.RefreshMode
		,srmd.NodeStatus
		,srmd.ResourcesInDesiredStateCount
		,srmd.ResourcesNotInDesiredStateCount
		,srmd.ResourcesNotInDesiredState
		,srmd.ErrorMessage
		,srmd.Duration
		,srmd.DurationWithOverhead
	FROM dbo.StatusReport AS sr
		 INNER JOIN dbo.StatusReportMetaData AS srmd
		 ON sr.JobId = srmd.JobId
		 INNER JOIN (SELECT MAX(CreationTime) AS MaxCreationTime, NodeName
					 FROM dbo.StatusReportMetaData
					 GROUP BY NodeName) AS srmdmax
					 ON sr.NodeName = srmdmax.NodeName AND srmd.CreationTime = srmdmax.MaxCreationTime
) AS nss
GO


/****** Object:  View [dbo].[vNodeStatusComplex]    Script Date: 07.04.2021 16:59:54 ******/
CREATE VIEW [dbo].[vNodeStatusComplex]
AS
SELECT GetNodeStatus.*,
IIF([ResourceCountNotInDesiredState] > 0 OR [ResourceCountInDesiredState] = 0, 'FALSE', 'TRUE') AS [InDesiredState]
FROM dbo.tvfGetNodeStatus() AS GetNodeStatus
GO

/****** Object:  View [dbo].[vNodeStatusCount]    Script Date: 07.04.2021 16:59:54 ******/
CREATE VIEW [dbo].[vNodeStatusCount]
AS
SELECT NodeName, COUNT(*) AS NodeStatusCount
FROM dbo.StatusReport
WHERE (NodeName IS NOT NULL)
GROUP BY NodeName
GO

/****** Object:  View [dbo].[vStatusReportDataNewest]    Script Date: 07.04.2021 16:59:54 ******/
CREATE VIEW [dbo].[vStatusReportDataNewest]
AS
SELECT TOP (1000) dbo.StatusReport.JobId,dbo.RegistrationData.NodeName, dbo.StatusReport.OperationType, dbo.StatusReport.RefreshMode, dbo.StatusReport.Status, dbo.StatusReportMetaData.CreationTime, 
dbo.StatusReport.StartTime, dbo.StatusReport.EndTime, dbo.StatusReport.Errors, dbo.StatusReport.StatusData
FROM dbo.StatusReport
INNER JOIN dbo.StatusReportMetaData ON dbo.StatusReport.JobId = dbo.StatusReportMetaData.JobId
INNER JOIN dbo.RegistrationData ON dbo.StatusReport.Id = dbo.RegistrationData.AgentId
ORDER BY dbo.StatusReportMetaData.CreationTime DESC
GO

/****** Object:  View [dbo].[vNodeLastStatus]    Script Date: 4/6/2021 10:53:28 AM ******/
Create View [dbo].[vNodeLastStatus]
AS
SELECT sr.[JobId]
      ,sr.[Id]
      ,sr.[OperationType]
      ,sr.[RefreshMode]
      ,sr.[Status]
      ,sr.[LCMVersion]
      ,sr.[ReportFormatVersion]
      ,sr.[ConfigurationVersion]
      ,sr.[NodeName]
      ,sr.[IPAddress]
      ,sr.[StartTime]
      ,sr.[EndTime]
      ,sr.[Errors]
      ,sr.[StatusData]
      ,sr.[RebootRequested]
      ,sr.[AdditionalData]
      ,srmd.[CreationTime]
  FROM [dbo].[StatusReport] sr
  INNER JOIN [dbo].[StatusReportMetaData] srmd ON sr.JobId = srmd.JobId
  INNER JOIN [dbo].[vNodeStatusSimple] vnss ON sr.NodeName = vnss.NodeName AND sr.StartTime = vnss.StartTime
GO

/****** Object:  View [dbo].[vTaggingData]    Script Date: 4/6/2021 10:53:28 AM ******/
Create View [dbo].[vTaggingData]
AS
SELECT rg.NodeName
      ,tg.[AgentId]
      ,tg.[Environment]
      ,tg.[BuildNumber]
      ,tg.[GitCommitId]
      ,tg.[NodeVersion]
      ,tg.[NodeRole]
      ,tg.[Version]
      ,tg.[BuildDate]
      ,tg.[Timestamp]
      ,tg.[Layers]
  FROM [dbo].[TaggingData] tg
  INNER JOIN [dbo].[RegistrationData] rg on rg.AgentId = tg.AgentId
GO

-- Trigger

CREATE TRIGGER [dbo].[InsertRegistrationMetaData]
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

CREATE TRIGGER [dbo].[InsertUpdateStatusReportMetaData]
ON [dbo].[StatusReport]
AFTER INSERT, UPDATE
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- get the last id value of the record inserted or updated
    DECLARE @JobId nvarchar(255)
    DECLARE @NodeName nvarchar(255)
    DECLARE @NodeStatus nvarchar(50)
    DECLARE @HostName nvarchar(50)
    DECLARE @ErrorMessage nvarchar(2500)
    DECLARE @ResourcesInDesiredStateCount int
    DECLARE @ResourcesNotInDesiredStateCount int
    DECLARE @ResourcesInDesiredState nvarchar(max)
    DECLARE @ResourcesNotInDesiredState nvarchar(max)
    DECLARE @Duration float
    DECLARE @DurationWithOverhead float

    SELECT @JobId = JobId
        ,@NodeName = NodeName
        ,@ResourcesInDesiredStateCount =
            (SELECT COUNT(*)
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
                )
            )
        ,@ResourcesNotInDesiredStateCount =
            (SELECT COUNT(*)
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesNotInDesiredState')
                )
            )
        ,@ErrorMessage = 
            (SELECT [ResourceId] + ':' + ' (' + [ErrorCode] + ') ' + [ErrorMessage] + ',' AS [text()]
                FROM OPENJSON(
                    (SELECT TOP 1  [value] FROM OPENJSON([Errors]))
                )
                WITH (
                    ErrorMessage nvarchar(2000) '$.ErrorMessage',
                    ErrorCode nvarchar(20) '$.ErrorCode',
                    ResourceId nvarchar(200) '$.ResourceId'
                ) 
                FOR XML PATH ('')
            )
        ,@HostName =
            (SELECT [HostName]
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON([StatusData]))
                )
                WITH (
                    HostName nvarchar(50) '$.HostName'
                )
            )
        ,@ResourcesInDesiredState =
            (SELECT [ResourceId] + ',' AS [text()]
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
                )
                WITH (
                    ResourceId nvarchar(200) '$.ResourceId'
                )
                FOR XML PATH ('')
            )
        ,@ResourcesNotInDesiredState = 
            (SELECT [ResourceId] + ',' AS [text()]
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesNotInDesiredState')
                )
                WITH (
                    ResourceId nvarchar(200) '$.ResourceId'
                )
                FOR XML PATH ('')
            )
        ,@Duration =
            (SELECT SUM(CAST(REPLACE(DurationInSeconds, ',', '.') AS float))
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON((SELECT [value] FROM OPENJSON([StatusData]))) WHERE [key] = 'ResourcesInDesiredState')
                )
                WITH (
                    DurationInSeconds nvarchar(50) '$.DurationInSeconds',
                    InDesiredState bit '$.InDesiredState'
                )
            )
        ,@DurationWithOverhead =
            (SELECT SUM(CAST(REPLACE(DurationInSeconds, ',', '.') AS float))
                FROM OPENJSON(
                    (SELECT [value] FROM OPENJSON([StatusData]))
                )
                WITH (
                    DurationInSeconds nvarchar(50) '$.DurationInSeconds'
                )
            )
    FROM INSERTED

    SELECT @NodeStatus =
            CASE WHEN NodeName IS NULL AND RefreshMode IS NOT NULL THEN 'No data' ELSE
            CASE WHEN NodeName IS NULL AND RefreshMode IS NULL THEN 'LCM Error' ELSE
            CASE WHEN NodeName IS NOT NULL AND RefreshMode IS NULL AND Status IS NULL THEN 'LCM is running' ELSE
            CASE WHEN NodeName IS NOT NULL AND Status IS NULL THEN 'Error' ELSE
            CASE WHEN NodeName IS NOT NULL AND OperationType != 'LocalConfigurationManager' AND Status = 'Success' AND @ResourcesInDesiredStateCount > 0 AND @ResourcesNotInDesiredStateCount > 0 THEN 'Not in Desired State' ELSE
            CASE WHEN NodeName IS NOT NULL AND OperationType != 'LocalConfigurationManager' AND Status = 'Success' AND @ResourcesInDesiredStateCount > 0 AND @ResourcesNotInDesiredStateCount = 0 THEN 'In Desired State' ELSE
            CASE WHEN NodeName IS NOT NULL AND OperationType = 'LocalConfigurationManager' THEN 'Unknown' ELSE
            CASE WHEN NodeName IS NOT NULL THEN Status END END END END END END END END
    FROM INSERTED

    IF EXISTS(SELECT * FROM deleted)
    BEGIN
        UPDATE [StatusReportMetaData]
        SET
            NodeName                         = @NodeName
            ,NodeStatus                      = @NodeStatus
            ,ErrorMessage                    = @ErrorMessage
            ,ResourcesInDesiredStateCount    = @ResourcesInDesiredStateCount
            ,ResourcesNotInDesiredStateCount = @ResourcesNotInDesiredStateCount
            ,ResourceCount                   = @ResourcesInDesiredStateCount + @ResourcesNotInDesiredStateCount
            ,HostName                        = @HostName
            ,ResourcesInDesiredState         = @ResourcesInDesiredState
            ,ResourcesNotInDesiredState      = @ResourcesNotInDesiredState
            ,Duration                        = @Duration
            ,DurationWithOverhead            = @DurationWithOverhead
        WHERE
            JobId = @JobId
    END
    ELSE
    BEGIN
        INSERT INTO [StatusReportMetaData]
            (
                JobId, NodeName, NodeStatus, ErrorMessage, HostName,
                ResourcesInDesiredState, ResourcesNotInDesiredState,
                ResourcesInDesiredStateCount, ResourcesNotInDesiredStateCount, ResourceCount,
                Duration, DurationWithOverhead, CreationTime
            )
            VALUES
            (
                @JobId, @NodeName, @NodeStatus, @ErrorMessage, @HostName,
                @ResourcesInDesiredState, @ResourcesNotInDesiredState,
                @ResourcesInDesiredStateCount, @ResourcesNotInDesiredStateCount, (@ResourcesInDesiredStateCount + @ResourcesNotInDesiredStateCount),
                @Duration, @DurationWithOverhead, GETDATE()
            )
    END
END
GO

ALTER TABLE [dbo].[StatusReport] ENABLE TRIGGER [InsertUpdateStatusReportMetaData]
ALTER TABLE [dbo].[RegistrationData] ENABLE TRIGGER [InsertRegistrationMetaData]
GO

CREATE TRIGGER [dbo].[InsertNodeLastStatusData]
ON [dbo].[StatusReport]
AFTER UPDATE
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements.
  SET NOCOUNT ON;

  -- get the last id value of the record inserted or updated
  DECLARE @NodeName nvarchar(30)
  DECLARE @StatusData nvarchar(max)
  DECLARE @status varchar(10)
  SELECT @NodeName = NodeName, @StatusData = StatusData, @status = Status
  FROM INSERTED

       IF @status = 'Success'
       Begin
         --create temp table
         IF OBJECT_ID('tempdb..#TempJSON') IS NOT NULL
                DROP TABLE #TempJSON

         CREATE TABLE #TempJSON(
                [NodeName] [varchar](30) NOT NULL,
                [NumberOfResources] [int] NULL,
                [DscMode] [varchar](10) NULL,
                [DscConfigMode] [varchar](100) NULL,
                [ActionAfterReboot] [varchar](50) NULL,
                [ReapplyMOFCycle] [int] NULL,
                [CheckForNewMOF] [int] NULL,
                [PullServer] [varchar](30) NULL,
                [LastUpdate] datetime)
             --split JSON
                    DECLARE @j VARCHAR(max)
                    SET @j = (SELECT REPLACE(Replace(REPLACE(@StatusData,'["{','[{'),'}"]','}]'),'\"','"'));

                    WITH ReadableJSON AS (
                    SELECT
                              json_value(@j, '$[0].HostName') AS NodeName,   
                              json_value(@j, '$[0].NumberOfResources') AS NumberOfResources,
                              json_value(@j, '$[0].Mode') AS DscMode,
                              json_value(@j, '$[0].MetaConfiguration.ConfigurationMode') AS DscConfigMode,
                              json_value(@j, '$[0].MetaConfiguration.ActionAfterReboot') AS ActionAfterReboot,
                              json_value(@j, '$[0].MetaConfiguration.RefreshFrequencyMins') AS ReapplyMOFCycle,
                              json_value(@j, '$[0].MetaConfiguration.ConfigurationModeFrequencyMins') AS CheckForNewMOF,
                              substring(json_value(@j, '$[0].MetaConfiguration.ConfigurationDownloadManagers[0].ServerURL'), 9, 15) AS PullServer,
                              GETDATE() AS LastUpdated
                    FROM OPENJSON(@j)
                    ) INSERT INTO #TempJSON SELECT * FROM ReadableJSON

         -- Insert statements for trigger here
         IF NOT EXISTS (SELECT NodeName FROM dbo.NodeLastStatusData WHERE NodeName = @NodeName)
        BEGIN
            INSERT INTO [NodeLastStatusData] (NodeName, NumberOfResources, DscMode, DscConfigMode, ActionAfterReboot, ReapplyMOFCycle, CheckForNewMOF, PullServer, LastUpdate)
                SELECT NodeName, NumberOfResources, DscMode, DscConfigMode, ActionAfterReboot, ReapplyMOFCycle, CheckForNewMOF, PullServer, LastUpdate FROM #TempJSON
        END
        ELSE
        BEGIN
            UPDATE [NodeLastStatusData]
                SET NumberOfResources = #TempJSON.NumberOfResources, DscMode = #TempJSON.DscMode, DscConfigMode = #TempJSON.DscConfigMode, ActionAfterReboot = #TempJSON.ActionAfterReboot, ReapplyMOFCycle = #TempJSON.ReapplyMOFCycle, CheckForNewMOF = #TempJSON.CheckForNewMOF, PullServer = #TempJSON.PullServer, LastUpdate = #TempJSON.LastUpdate
                FROM [NodeLastStatusData] nlsd
                INNER JOIN #TempJSON ON nlsd.NodeName = #TempJSON.NodeName
                WHERE nlsd.NodeName = #TempJSON.NodeName
        END
    END
END

GO

ALTER TABLE [dbo].[StatusReport] ENABLE TRIGGER [InsertNodeLastStatusData]
GO

USE [master]
GO
ALTER DATABASE [DSC] SET READ_WRITE 
GO
'@

if (-not $UseNewFeature)
{
	$createDbQuery = $createDbQuery.Replace('WITH CATALOG_COLLATION = DATABASE_DEFAULT','')
	$createDbQuery = $createDbQuery.Replace(', OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF','')
}

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

	Invoke-Sqlcmd -Query $createDbQuery -ServerInstance localhost

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
