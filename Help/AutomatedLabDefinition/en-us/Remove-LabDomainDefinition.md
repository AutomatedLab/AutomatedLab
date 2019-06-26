---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Remove-LabDomainDefinition

## SYNOPSIS
Remove a domain definition

## SYNTAX

```
Remove-LabDomainDefinition [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Removes a domain definition from the lab domain definitions

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabDomainDefinition -Name a.contoso.com
```

In order not to start over entirely, remove a single domain definition from the lab

## PARAMETERS

### -Name
The name of the domain definition to remove

```yaml
Type: String
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

## OUTPUTS

## NOTES

## RELATED LINKS
