---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# Save-LabRecipe

## SYNOPSIS
Save a lab recipe to disk

## SYNTAX

```
Save-LabRecipe [-Recipe] <PSObject> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Save a lab recipe to disk

## EXAMPLES

### Example 1
```powershell
LabRecipe SuperEasy {
    DeployRole = 'Domain', 'PKI'
} | Save-LabRecipe
```

Saves the recipe SuperEasy

## PARAMETERS

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recipe
The recipe to store

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
