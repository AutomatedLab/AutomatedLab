---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Checkpoint-LabVM

## SYNOPSIS
Create a VM checkpoint

## SYNTAX

### ByName
```
Checkpoint-LabVM -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

### All
```
Checkpoint-LabVM -SnapshotName <String> [-All] [<CommonParameters>]
```

## DESCRIPTION
This function creates a checkpoint of a lab virtual machine running on HyperV

## EXAMPLES

### Example 1


```powershell
Checkpoint-LabVM -All -SnapshotName 'FirstSnapshot'
```

Creates a snapshot called FirstSnapshot for all machines of a given lab

## PARAMETERS

### -ComputerName
The computer name

```yaml
Type: String[]
Parameter Sets: ByName
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
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Switch parameter to snapshot all lab VMs

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
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
