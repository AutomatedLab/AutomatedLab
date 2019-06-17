---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version:
schema: 2.0.0
---

# Remove-LabRecipe

## SYNOPSIS
Remove a stored recipe

## SYNTAX

### ByName
```
Remove-LabRecipe -Name <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByRecipe
```
Remove-LabRecipe -Recipe <PSCustomObject> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Remove a stored recipe. Does not remove any lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabRecipe -Name MyBuildEnvironment
```

Removes the recipe MyBuildEnvironment

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

### -Name
Name of the recipe

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Recipe
Recipe to remove

```yaml
Type: PSCustomObject
Parameter Sets: ByRecipe
Aliases:

Required: True
Position: Named
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

### System.String

### System.Management.Automation.PSCustomObject

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
