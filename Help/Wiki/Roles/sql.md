# SQL Server

The SQL Server role can be used to deploy any SQL Server version starting from SQL Server 2008 to 2019 on Windows. The installation can be customized like a normal SQL Server setup by using all available parameters or a configuration file.

During the installation, all service accounts that are referenced will be created automatically unless they already exist. On Azure, by default a managed instance is deployed, unless role parameters are used that would prevent this. If for instance different service accounts are configured, a normal IaaS VM will be deployed and SQL will be installed from an ISO file that needs to be present in your LabSources folder on Azure.

Starting with SQL Server 2017 the SQL Server Reporting Services need to be downloaded. On an online lab host, the package will be downloaded automatically. Should you be offline, please store the download as `"$LabSources\SoftwarePackages\SQLServerReportingServices.exe"`.

## Role assignment

To deploy a default SQL Server, simply assign the role. This will include sample databases as well.

```powershell
Add-LabMachineDefinition -Name SQL01 -Roles SQLServer2017
```

If you need a little more control, simply use the role properties. The following example only installs the engine and tools:

```powershell
$role = Get-LabMachineRoleDefinition -Role SQLServer2017 -RoleProperties @{Features = 'SQL,Tools'}

Add-LabMachineDefinition -Name SQL01 -Roles $role
```

## Role properties

All role properties are entirely optional.

### Features

Features contains a string with the comma-separated features to install, as you would supply them on the command line. For example `@{Features = 'SQL,Tools'}`.

### ConfigurationFile

Specify the full (local) path to the configuration file that contains your setup parameters. You can still override single parameters.

### InstanceName

Name of the instance to deploy. Default is MSSQLSERVER

### Collation

The collation to use

### SQLSvcAccount

The account name of the SQL service user

### SQLSvcPassword

The plaintext password of the SQL service user

### AgtSvcAccount

Agent Service account

### AgtSvcPassword

Agent Service account password

### RsSvcAccount

Reporting Services account

### RsSvcPassword

Reporting Services account password

### AgtSvcStartupType

Agent Service start type

### BrowserSvcStartupType

Browser Service start type

### RsSvcStartupType

Reporting Services start type

### AsSysAdminAccounts

Analysis Services admin accounts

### AsSvcAccount

Analysis Services account

### AsSvcPassword

Analysis Services account password

### IsSvcAccount

Integration Services account

### IsSvcPassword

Integration Services account password

### SQLSysAdminAccounts

The comma-separated list of administrative accounts

## Configuration settings

There are several configuration settings that can be updated in case URLs change. To discover all available settings, please refer to  
```powershell
Get-PSFConfig -Module AutomatedLab -Name SQL*
```
