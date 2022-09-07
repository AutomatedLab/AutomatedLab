---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Remove-LabCimSession
schema: 2.0.0
---

# Remove-LabCimSession

## SYNOPSIS
Remove open CIM sessions to lab VMs

## SYNTAX

### ByName
```
Remove-LabCimSession -ComputerName <String[]> [<CommonParameters>]
```

### ByMachine
```
Remove-LabCimSession -Machine <Machine[]> [<CommonParameters>]
```

### All
```
Remove-LabCimSession [-All] [<CommonParameters>]
```

## DESCRIPTION
Remove open CIM sessions to lab VMs

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabCimSession -All
```

Remove open CIM sessions to lab VMs

## PARAMETERS

### -All
Indicates that all lab CIM sessions should be removed

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
List of lab machine names

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
List of lab machine objects

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

