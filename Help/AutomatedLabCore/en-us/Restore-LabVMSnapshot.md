---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Restore-LabVMSnapshot
schema: 2.0.0
---

# Restore-LabVMSnapshot

## SYNOPSIS
Restore a snapshot

## SYNTAX

### ByName
```
Restore-LabVMSnapshot -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

### All
```
Restore-LabVMSnapshot -SnapshotName <String> [-All] [<CommonParameters>]
```

## DESCRIPTION
Restores a named snapshot on one or more machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Restore-LabVMSnapshot -SnapshotName BeforeDestroyingTheWorld -All
```

Restore the snapshot from before destroying the world.

## PARAMETERS

### -All
Indicates that the snapshot should be restored on all machines

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
The computer names

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

