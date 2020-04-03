---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-LabPSSession

## SYNOPSIS
Remove sessions

## SYNTAX

### ByName
```
Remove-LabPSSession -ComputerName <String[]> [<CommonParameters>]
```

### ByMachine
```
Remove-LabPSSession -Machine <Machine[]> [<CommonParameters>]
```

### All
```
Remove-LabPSSession [-All] [<CommonParameters>]
```

## DESCRIPTION
Removes one or more PowerShell sessions currently active

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabPSSession -ComputerName DC01
```

Explicitly remove a session in order to create a new one.

## PARAMETERS

### -ComputerName
The computer names for which sessions should be removed

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Machine
The lab machines for which sessions should be removed

```yaml
Type: Machine[]
Parameter Sets: ByMachine
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Indicates that all sessions should be removed

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
