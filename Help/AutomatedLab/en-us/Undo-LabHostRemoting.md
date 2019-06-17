---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Undo-LabHostRemoting

## SYNOPSIS
Reset the local policy values to their defaults

## SYNTAX

```
Undo-LabHostRemoting [-Force] [-NoDisplay]
```

## DESCRIPTION
Reset the local policy values to their defaults. See Enable-LabHostRemoting for those settings.

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
Default value: None
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
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
