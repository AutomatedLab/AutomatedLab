---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWProxmoxVmSnapshot
schema: 2.0.0
---

# Get-LWProxmoxVmSnapshot

## SYNOPSIS

Retrieves snapshots of Proxmox virtual machines

## SYNTAX

```
Get-LWProxmoxVmSnapshot [[-ComputerName] <String[]>] [[-SnapshotName] <String>] [<CommonParameters>]
```

## DESCRIPTION

Retrieves snapshots for one or more Proxmox virtual machines. Can filter by snapshot name.

## EXAMPLES

### Example 1

```powershell
Get-LWProxmoxVmSnapshot -ComputerName DC01
```

Retrieves all snapshots for the DC01 virtual machine

### Example 2

```powershell
Get-LWProxmoxVmSnapshot -ComputerName DC01 -SnapshotName BeforeSchemaUpdate
```

Retrieves a specific snapshot by name for the DC01 virtual machine

### Example 3

```powershell
Get-LWProxmoxVmSnapshot -ComputerName DC01,SQL01
```

Retrieves all snapshots for multiple virtual machines

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to retrieve snapshots for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: VMName

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotName

The name of a specific snapshot to retrieve

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### AutomatedLab.Snapshot

## NOTES

## RELATED LINKS
