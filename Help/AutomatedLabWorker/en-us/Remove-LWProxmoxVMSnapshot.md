---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWProxmoxVMSnapshot
schema: 2.0.0
---

# Remove-LWProxmoxVMSnapshot

## SYNOPSIS

Removes snapshots from Proxmox virtual machines

## SYNTAX

### BySnapshotName

```
Remove-LWProxmoxVMSnapshot -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

### AllSnapshots

```
Remove-LWProxmoxVMSnapshot -ComputerName <String[]> [-All] [<CommonParameters>]
```

## DESCRIPTION

Removes one or more snapshots from Proxmox virtual machines. Can remove a specific snapshot by name or all snapshots for a VM.

## EXAMPLES

### Example 1

```powershell
Remove-LWProxmoxVMSnapshot -ComputerName DC01 -SnapshotName BeforeSchemaUpdate
```

Removes a specific snapshot from the DC01 virtual machine

### Example 2

```powershell
Remove-LWProxmoxVMSnapshot -ComputerName DC01 -All
```

Removes all snapshots from the DC01 virtual machine

### Example 3

```powershell
Remove-LWProxmoxVMSnapshot -ComputerName DC01,SQL01 -SnapshotName BeforePatching
```

Removes the same snapshot from multiple virtual machines

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to remove snapshots from

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotName

The name of the snapshot to remove. Must not contain spaces.

```yaml
Type: String
Parameter Sets: BySnapshotName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All

Remove all snapshots from the specified virtual machine(s)

```yaml
Type: SwitchParameter
Parameter Sets: AllSnapshots
Aliases:

Required: False
Position: Named
Default value: False
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
