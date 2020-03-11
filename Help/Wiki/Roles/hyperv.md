# Hyper-V

AutomatedLab can deploy Hyper-V VMs on a system that allows nested virtualization, e.g. Windows 10.

## Role assignment

To create a new hypervisor in your lab, simply assign it the HyperV role:

```powershell
Add-LabMachineDefinition -Name HV01 -Roles HyperV
```

You can also customize many relevant settings by creating the role definition reference:

```powershell
$role = Get-LabMachineRoleDefinition -Role HyperV -RoleProperties @{EnableEnhancedSessionMode = 'true'}
Add-LabMachineDefinition -Name HV01 -Roles $role
```
## Role properties

The following role properties can be assigned and are entirely optional:

### MaximumStorageMigrations

The maximum number of concurrent storage migrations

### MaximumVirtualMachineMigrations

The maximum number of concurrent VM migrations

### VirtualMachineMigrationAuthenticationType

The authentication method used for live migrations (CredSSP, Kerberos)

### UseAnyNetworkForMigration

Indicates that any network may be used for live migrations

### VirtualMachineMigrationPerformanceOption

Compression, SMB, TCPIP

### ResourceMeteringSaveInterval

The interval in which metering information is stored

### NumaSpanningEnabled

Indicates that NUMA spanning will be enabled

### EnableEnhancedSessionMode

Indicates that the enhanced session mode is available
