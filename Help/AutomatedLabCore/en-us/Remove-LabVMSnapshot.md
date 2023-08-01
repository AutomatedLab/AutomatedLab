---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Remove-LabVMSnapshot
schema: 2.0.0
---

# Remove-LabVMSnapshot

## SYNOPSIS
Remove a snapshot

## SYNTAX

### ByNameSnapshotByName
```
Remove-LabVMSnapshot -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

### ByNameAllSnapShots
```
Remove-LabVMSnapshot -ComputerName <String[]> [-AllSnapShots] [<CommonParameters>]
```

### AllMachinesSnapshotByName
```
Remove-LabVMSnapshot -SnapshotName <String> [-AllMachines] [<CommonParameters>]
```

### AllMachinesAllSnapshots
```
Remove-LabVMSnapshot [-AllMachines] [-AllSnapShots] [<CommonParameters>]
```

## DESCRIPTION
Removes a named snapshot or all snapshots for one or more machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabVMSnapshot -SnapshotName Snappy01 -AllMachines
```

Remove Snappy01 for all lab machines

## PARAMETERS

### -AllMachines
Indicates that the snapshot should be removed for all machines

```yaml
Type: SwitchParameter
Parameter Sets: AllMachinesSnapshotByName, AllMachinesAllSnapshots
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AllSnapShots
Indicates that all snapshots of the current lab should be removed

```yaml
Type: SwitchParameter
Parameter Sets: ByNameAllSnapShots, AllMachinesAllSnapshots
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
The hosts to remove a snapshot from

```yaml
Type: String[]
Parameter Sets: ByNameSnapshotByName, ByNameAllSnapShots
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SnapshotName
The snapshot name

```yaml
Type: String
Parameter Sets: ByNameSnapshotByName, AllMachinesSnapshotByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

