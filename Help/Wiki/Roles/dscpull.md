# DSC Pull Server

With the DSCPullServer role, new pull or reporting servers for Desired State Configuration can be deployed. This role requires a certificate authority somewhere in the lab environment. Internet connectivity of the lab host is recommended, but not required. If your host is not connected, make sure that xPSDesiredStateConfiguration, xWebAdministration and xDscDiagnostics are in your module path.

Starting with Server 1809 (guest operating system) you can choose to deploy the pull server with a SQL backend. This option requires a SQL Server in the lab which will host the DSC database.

## Role assigmnent

The default role assignment deploys a standard SSL DSC Pull Server using an edb backend.

```powershell
Add-LabMachineDefinition -Name Pulli -Roles DscPullServer
```

You can optionally specify parameters by using the role definition:

```powershell
$role = Get-LabMachineRoleDefinition -Role DscPullServer -RoleProperties @{
    DatabaseEngine = 'mdb'
    DatabaseName = 'DSC'
    DatabaseServer = 'SQL01'
    }

Add-LabMachineDefinition -Name Pulli -Roles $role
```

## Role properties

### DoNotPushLocalModules

Indicates that locally installed DSC resources may not be pushed to the pull server

### DatabaseEngine

Which database engine will be used. Either edb or mdb. Default is edb.

### DatabaseName

The name of the database to deploy if mdb is selected.

### DatabaseServer

The name of the database server to deploy the database on if mdb is selected
