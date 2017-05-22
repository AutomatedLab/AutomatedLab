param (
    [Parameter(Mandatory)]
    [string]$DomainName,

    [Parameter(Mandatory)]
    [string]$ComputerName
)

$query = @'
USE [master]
GO

CREATE LOGIN [{0}\{1}] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

/****** Object:  Database [DSC]    Script Date: 4/15/2017 8:46:34 PM ******/
CREATE DATABASE [DSC]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DSC', FILENAME = N'C:\DSCDB\DSC.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DSC_log', FILENAME = N'C:\DSCDB\DSC_log.ldf' , SIZE = 2048KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
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

ALTER DATABASE [DSC] SET RECOVERY FULL 
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

CREATE TRIGGER [dbo].[DSCStatusReportOnUpdate]
   ON  [dbo].[StatusReport] 
   AFTER UPDATE
AS
SET NOCOUNT ON
BEGIN
    DECLARE @JobId nvarchar(50) = (SELECT JobId FROM inserted);
    DECLARE @StatusData nvarchar(MAX) = (SELECT StatusData FROM inserted);
    IF @StatusData LIKE '\[%' ESCAPE '\'
        SET @StatusData = REPLACE(SUBSTRING(@StatusData, 3, Len(@StatusData) - 4), '\', '')

    DECLARE @Errors nvarchar(MAX) = (SELECT [Errors] FROM inserted);
    IF @Errors IS NULL
        SET @Errors = (SELECT Errors FROM StatusReport WHERE JobId = @JobId)
    
    IF @Errors LIKE '\[%' ESCAPE '\' AND Len(@Errors) > 4
        SET @Errors = REPLACE(SUBSTRING(@Errors, 3, Len(@Errors) - 4), '\', '')

    UPDATE StatusReport
    SET StatusData = @StatusData, Errors = @Errors
    WHERE JobId = @JobId
    
END
GO

ALTER TABLE [dbo].[StatusReport] ENABLE TRIGGER [DSCStatusReportOnUpdate]
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
    SELECT dbo.StatusReport.NodeName, dbo.StatusReport.Id AS AgentId, dbo.StatusReport.Status, dbo.StatusReport.StartTime, dbo.StatusReport.EndTime
    
    ,(
        SELECT SUM(DurationInSeconds) AS Duration
        FROM OPENJSON ((SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesInDesiredState'))  
        WITH (   
            DurationInSeconds     float       '$.DurationInSeconds',
            InDesiredState bit '$.InDesiredState'
        ) GROUP BY InDesiredState
    ) AS Duration
    -- ,(
    -- SELECT SUM(CAST(REPLACE(DurationInSeconds, ',','.') AS float)) AS Duration
    -- 	FROM OPENJSON ((SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesInDesiredState'))  
    -- 	WITH (   
    -- 		DurationInSeconds     nvarchar(50)       '$.DurationInSeconds',
    -- 		InDesiredState bit '$.InDesiredState'
    -- 	) GROUP BY InDesiredState
    -- ) AS Duration
    ,(
        SELECT COUNT(*) AS ResourceCount
        FROM OPENJSON ((SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesInDesiredState'))  
        WITH (
            InDesiredState bit '$.InDesiredState'
        ) GROUP BY InDesiredState
    ) AS ResourceCountInDesiredState
    ,(
        SELECT COUNT(*) AS ResourceCount
        FROM OPENJSON ((SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesNotInDesiredState'))  
        WITH (
            NotInDesiredState bit '$.NotInDesiredState'
        ) GROUP BY NotInDesiredState
    ) AS ResourceCountNotInDesiredState
    ,(
        SELECT [ResourceId] + ',' AS [text()]
        FROM OPENJSON ((SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesNotInDesiredState'))  
        WITH (
            ResourceId nvarchar(100) '$.ResourceId'
        ) FOR XML PATH ('')
    ) AS ResourceIdsNotInDesiredState
    ,(
        SELECT [Value] FROM OPENJSON([StatusData]) WHERE [Key] = 'ResourcesInDesiredState'
    ) AS RawStatusData
    
    ,(
        SELECT [VersionString] FROM OPENJSON((
            SELECT [Value] FROM OPENJSON([AdditionalData])
            WITH(
                [Key] nvarchar(100) '$.Key',
                [Value] nvarchar(100) '$.Value'
            )
            WHERE [Key] = 'OSVersion'
        ))
        WITH(
            [VersionString] nvarchar(100) '$.VersionString',
            [ServicePack] nvarchar(100) '$.ServicePack',
            [Platform] nvarchar(100) '$.Platform'
        )
    ) AS OSVersion

    ,(
        SELECT [PSVersion] FROM OPENJSON((
            SELECT [Value] FROM OPENJSON([AdditionalData])
            WITH(
                [Key] nvarchar(100) '$.Key',
                [Value] nvarchar(100) '$.Value'
            )
            WHERE [Key] = 'PSVersion'
        ))
        WITH(
            [CLRVersion] nvarchar(100) '$.CLRVersion',
            [PSVersion] nvarchar(100) '$.PSVersion',
            [BuildVersion] nvarchar(100) '$.BuildVersion'
        )
    ) AS PSVersion

    FROM dbo.StatusReport INNER JOIN
    (SELECT MAX(EndTime) AS MaxEndTime, NodeName
    FROM dbo.StatusReport AS StatusReport_1
    GROUP BY NodeName) AS SubMax ON dbo.StatusReport.EndTime = SubMax.MaxEndTime AND dbo.StatusReport.NodeName = SubMax.NodeName
)
GO

-- Adding views
CREATE VIEW [dbo].[vRegistrationData]
AS
SELECT GetRegistrationData.*
FROM dbo.tvfGetRegistrationData() AS GetRegistrationData
GO

CREATE VIEW [dbo].[vNodeStatusSimple]
AS
SELECT dbo.StatusReport.NodeName, dbo.StatusReport.Status, dbo.StatusReport.EndTime AS Time
FROM dbo.StatusReport INNER JOIN
    (SELECT MAX(EndTime) AS MaxEndTime, NodeName
    FROM dbo.StatusReport AS StatusReport_1
    GROUP BY NodeName) AS SubMax ON dbo.StatusReport.EndTime = SubMax.MaxEndTime AND dbo.StatusReport.NodeName = SubMax.NodeName
GO

CREATE VIEW [dbo].[vNodeStatusComplex]
AS
SELECT GetNodeStatus.*
FROM dbo.tvfGetNodeStatus() AS GetNodeStatus
GO

CREATE VIEW [dbo].[vNodeStatusCount]
AS
SELECT NodeName, COUNT(*) AS NodeStatusCount
FROM dbo.StatusReport
WHERE (NodeName IS NOT NULL)
GROUP BY NodeName
GO

-- Adding Permissions
CREATE USER [{1}] FOR LOGIN [{0}\{1}] WITH DEFAULT_SCHEMA=[db_datareader]
GO

ALTER ROLE [db_datareader] ADD MEMBER [{1}]
GO

ALTER ROLE [db_datawriter] ADD MEMBER [{1}]
GO
'@

$account = New-Object System.Security.Principal.NTAccount($DomainName, "$ComputerName$")
try
{
    $account.Translate([System.Security.Principal.SecurityIdentifier]) | Out-Null
}
catch
{
    Write-Error "The account '$DomainName\$ComputerName' could not be found"
    return
}

if (-not (Test-Path -Path C:\DSCDB))
{
    mkdir -Path C:\DSCDB | Out-Null
}

if ($ComputerName -eq $env:COMPUTERNAME -and $DomainName -eq $env:USERDOMAIN)
{
    $DomainName = 'NT AUTHORITY'
    $ComputerName = 'SYSTEM'
}
else
{
    $ComputerName = $ComputerName + '$'
}

Write-Host "Creating the DSC database on the local default SQL instance..." -NoNewline
$query = $query -f $DomainName, $ComputerName

Invoke-Sqlcmd -Query $query -ServerInstance localhost

Write-Host 'finished.'
Write-Host 'Database is stored on C:\DSCDB'