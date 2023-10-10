---
external help file: AutomatedLabTest-help.xml
Module Name: AutomatedLabTest
online version: https://automatedlab.org/en/latest/AutomatedLabTest/en-us/New-LabPesterTest
schema: 2.0.0
---

# New-LabPesterTest

## SYNOPSIS
Helper to create new test harness for a new role

## SYNTAX

```
New-LabPesterTest [-Role] <String[]> [-Path] <String> [-IsCustomRole] [<CommonParameters>]
```

## DESCRIPTION
Helper to create new test harness for a new role

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabPesterTest -Role DynamicsFull -Path ./automatedlab.test/internal/tests
```

Create new test harness in a module subfolder

## PARAMETERS

### -IsCustomRole
Indicates that role is a Custom Role in that background

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to store test in

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

### -Role
Role to define test for. See `[enum]::GetValues([AutomatedLab.Roles])`
or <https://automatedlab.org/en/latest/Wiki/Roles/roles/> for more information.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

