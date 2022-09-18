---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Undo-LabHostRemoting
schema: 2.0.0
---

# Undo-LabHostRemoting

## SYNOPSIS
Reset the local policy values to their defaults

## SYNTAX

```
Undo-LabHostRemoting [-Force] [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Reset the local policy values to their defaults.
See Enable-LabHostRemoting for those settings.

## EXAMPLES

### Example 1
```powershell
PS C:\> Undo-LabHostRemoting -Force
```

Without user interaction, reset all values

## PARAMETERS

### -Force
Indicates that no interaction is requested

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

### -NoDisplay
Indicates that no console output should be returned

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

