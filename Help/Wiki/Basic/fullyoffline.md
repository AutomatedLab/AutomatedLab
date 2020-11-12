# Offline lab scenario

To deploy complex lab scenarios offline you will at some point run into issues due to additional dependencies being downloaded. This article aims to give you all the necessary information to prepare for a fully offline environment.

## Basics

First of all, install AutomatedLab from the MSI installer and get some ISO files - like you would for an online scenario. Place your ISO files in LabSources\ISOs. The MSI installer contains all static files that we need like ProductKeys.xml, WinSAT and so on.

## DSC Pull Server

To deploy the pull server role, we download the Access Database Engine from `Get-LabConfigurationItem -Name AccessDatabaseEngine2016x86` to LabSources/SoftwarePackages without renaming the file.

## Office

To deploy Office Server, the Office deployment toolkit is needed at LabSources/SoftwarePackages/OfficeDeploymentTool.exe. You can download the tool from `Get-LabConfigurationItem -Name OfficeDeploymentTool`.

## SharePoint

SharePoint requires a whole slew of prerequisites. First of all, you should download all CPP redistributables from 2012 up to 2017, 32 and 64 bit, following the naming pattern vcredist_BITS_YEAR e.g. vcredist_64_2012. The links can be easily accessed using `Get-LabConfigurationItem -Name cppredist*`. The more descriptive version is `Get-PSFConfig -Module AutomatedLab -Name cppredist*` which shows you the version as well. All packages need to be downloaded to LabSources/SoftwarePackages

The rest of the requirements is version-dependent. The links are best accessed using `Get-LabConfigurationItem -Name SharePoint2019Prerequisites`. Please make sure that for SharePoint 2013 the download with an URI containing 1CAA41C7 needs to be renamed to WcfDataServices56.exe.

## SQL

SQL also requires a bunch of prerequisites. First of all, you should download all CPP redistributables from 2015 up to 2017, 32 and 64 bit, following the naming pattern vcredist_xARCHITECTURE_YEAR e.g. vcredist_x86_2015.exe. The links can be easily accessed using `Get-LabConfigurationItem -Name cppredist*`. The more descriptive version is `Get-PSFConfig -Module AutomatedLab -Name cppredist*` which shows you the version as well. All packages need to be downloaded to LabSources/SoftwarePackages.

Additionally, .NET 4.8 will be required on SQL 2017 and newer when reporting services are deployed, which can be downloaded from `Get-LabConfigurationItem -Name dotnet48DownloadLink`. The download should be stored in LabSources/SoftwarePackages.

While not strictly required, you might want to download the following packages as well, thereby reducing some error messages:
- SQL Server Reporting Services: `Get-LabConfigurationItem -Name Sql$($server.SqlVersion)SSRS` to `LabSources/SoftwarePackages/Sql$($server.SqlVersion)\SQLServerReportingServices.exe`
- SQL Server Report Builder: `Get-LabConfigurationItem -Name SqlServerReportBuilder` to `LabSources\SoftwarePackages\ReportBuilder.msi`
- SQL Server Management Studio: `Get-LabConfigurationItem -Name Sql$($server.SqlVersion)ManagementStudio` to `LabSources/SoftwarePackages/Sql$($server.SqlVersion)/SSMS-Setup-ENU.exe`
- Sample Databases: Download the desired sample databases as .bak files to LabSources\SoftwarePackages\SqlSampleDbs\SqlServerXXXX. The files should be called as the directory, SqlServerXXXX.bak, where XXXX is the version of SQL.

## Team Foundation Server and Azure DevOps

A recent TFS/Azure DevOps agent is required which can be downloaded from `Get-LabConfigurationItem -Name BuildAgentUri` and needs to be stored as `LabSources\Tools\TfsBuildWorker.zip`.
