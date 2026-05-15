---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Checkpoint-LWProxmoxVM
schema: 2.0.0
---

# Checkpoint-LWProxmoxVM

## SYNOPSIS

Create a checkpoint of a Proxmox VM

## SYNTAX

```
Checkpoint-LWProxmoxVM [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION

Creates a snapshot of one or more Proxmox virtual machines. The snapshot can be used later to restore the VM to this point in time.

## EXAMPLES

### Example 1

```powershell
Checkpoint-LWProxmoxVM -ComputerName DC01 -SnapshotName BeforeSchemaUpdate
```

Creates the snapshot BeforeSchemaUpdate for Proxmox VM DC01

### Example 2

```powershell
Checkpoint-LWProxmoxVM -ComputerName DC01,SQL01 -SnapshotName BeforePatching
```

Creates the snapshot BeforePatching for multiple Proxmox VMs

## PARAMETERS

### -ComputerName

The machines to snapshot

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

The name of the snapshot. Must not contain spaces.

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
