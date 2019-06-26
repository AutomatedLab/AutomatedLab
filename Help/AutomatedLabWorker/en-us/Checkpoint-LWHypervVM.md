---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Checkpoint-LWHypervVM

## SYNOPSIS
Create a checkpoint of a Hyper-V VM

## SYNTAX

```
Checkpoint-LWHypervVM [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION
Create a checkpoint of a Hyper-V VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Checkpoint-LWHypervVm -ComputerName DC01 -SnapshotName BeforeSchemaUpdate
```

Creates the snapshot BeforeSchemaUpdate for host DC01

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
The name of the snapshot.

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
