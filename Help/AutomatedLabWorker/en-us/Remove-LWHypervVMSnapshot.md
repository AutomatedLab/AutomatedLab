---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Remove-LWHypervVMSnapshot

## SYNOPSIS
Remove Hyper-V checkpoints

## SYNTAX

### AllSnapshots
```
Remove-LWHypervVMSnapshot -ComputerName <String[]> [-All] [<CommonParameters>]
```

### BySnapshotName
```
Remove-LWHypervVMSnapshot -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

## DESCRIPTION
Remove Hyper-V checkpoints

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWHypervVMSnapshot -ComputerName HOst1,Host2 -SnapshotName AfterDeployment
```

Remove the checkpoint AfterDeployment from hosts Host1 and Host2

## PARAMETERS

### -All
Indicates that all snapshots should be removed

```yaml
Type: SwitchParameter
Parameter Sets: AllSnapshots
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The computers to remove snapshots of

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
The name of the snapshot to remove

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
