---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Restore-LWProxmoxVmSnapshot
schema: 2.0.0
---

# Restore-LWProxmoxVmSnapshot

## SYNOPSIS

Restores Proxmox virtual machines to a previous snapshot

## SYNTAX

```
Restore-LWProxmoxVmSnapshot [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION

Rolls each Proxmox VM in ComputerName back to the snapshot
`<VM name>_<SnapshotName>` that AutomatedLab created. The lab machines among
them that are running are stopped first and started again afterwards.

When a rollback task fails, the VM is rolled back again, at most
ProxmoxSnapshotRollbackRetries more times (default 2) and
ProxmoxSnapshotRollbackRetryDelaySeconds apart (default 20). Before each new
attempt the VM is read afresh from the cluster: a running VM is stopped, and a
lock in the VM configuration, for example 'rollback', gets at most one more
delay period to clear. A lock that stays ends the attempts for this VM, because
the Proxmox API cannot remove it. A task that ends with `WARNINGS: <n>` counts
as a successful rollback only when the VM is stopped and not locked afterwards.

All VMs are processed before a failure is reported. A VM whose rollback failed
is not started again. The function then throws one terminating error with the
error id ProxmoxSnapshotRollbackFailed that lists every failed VM with its
VMID, node, task UPID and the text of the Proxmox task.

A rollback request that the Proxmox API does not answer with status 200 still
ends the function at once. A VM without the snapshot is skipped with a warning
and started again if it was running.

## EXAMPLES

### Example 1

```powershell
Restore-LWProxmoxVmSnapshot -ComputerName DC01 -SnapshotName BeforeSchemaUpdate
```

Restores the DC01 VM to the BeforeSchemaUpdate snapshot

### Example 2

```powershell
Restore-LWProxmoxVmSnapshot -ComputerName DC01,SQL01 -SnapshotName BeforePatching
```

Restores multiple VMs to the same snapshot

## PARAMETERS

### -ComputerName

The names of the Proxmox VMs to restore, which are the resource names of the
lab machines.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotName

The name of the snapshot to restore to, without the prefix `<VM name>_`. Must
not contain spaces.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
