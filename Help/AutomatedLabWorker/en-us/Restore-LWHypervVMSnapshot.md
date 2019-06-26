---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Restore-LWHypervVMSnapshot

## SYNOPSIS
Restore a Hyper-V VM checkpoint

## SYNTAX

```
Restore-LWHypervVMSnapshot [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION
Restore a Hyper-V VM checkpoint.

## EXAMPLES

### Example 1
```powershell
PS C:\> Restore-LWHypervVMSnapshot -ComputerName DC01 -SnapshotName CP01
```

Restore checkpoint CP01 on DC01

## PARAMETERS

### -ComputerName
The host names to restore a snapshot from

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
The name of the snapshot to restore

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
