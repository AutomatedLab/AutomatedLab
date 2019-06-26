---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMSnapshot

## SYNOPSIS
Get the existing checkpoints of a lab VM

## SYNTAX

```
Get-LabVMSnapshot [[-ComputerName] <String[]>] [[-SnapshotName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get the existing checkpoints of a lab VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMSnapshot -ComputerName DC1
```

List all checkpoints of DC1

## PARAMETERS

### -ComputerName
The machine to list snapshots of

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SnapshotName
The snapshot to look for

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

### System.Object
## NOTES

## RELATED LINKS
