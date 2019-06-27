---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Remove-LabIsoImageDefinition

## SYNOPSIS
Remove ISO definition

## SYNTAX

```
Remove-LabIsoImageDefinition [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Removes an ISO image from the lab's image definitions

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabIsoImageDefinition -Name Sql2017
```

Remove the ISO for SQL Server 2017 from the current lab definition

## PARAMETERS

### -Name
The ISO name

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
