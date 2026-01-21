---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Restore-LWProxmoxVmSnapshot
schema: 2.0.0
---

# Restore-LWProxmoxVmSnapshot

## SYNOPSIS

Restores a Proxmox virtual machine to a previous snapshot

## SYNTAX

```
Restore-LWProxmoxVmSnapshot [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION

Restores one or more Proxmox virtual machines to a previously created snapshot. Running VMs will be stopped before restoration and can optionally be restarted.

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

The name(s) of the virtual machine(s) to restore

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

The name of the snapshot to restore to. Must not contain spaces.

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
