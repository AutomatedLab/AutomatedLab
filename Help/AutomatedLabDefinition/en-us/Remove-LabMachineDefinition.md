---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Remove-LabMachineDefinition

## SYNOPSIS
Remove a machine definition

## SYNTAX

```
Remove-LabMachineDefinition [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Removes a machine definition from the current lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabMachineDefinition -Name DC02
```

Remove DC02 from the lab machine definitions

## PARAMETERS

### -Name
The machine name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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
