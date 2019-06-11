---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-Lab

## SYNOPSIS
Show lab data

## SYNTAX

```
Get-Lab [-List] [<CommonParameters>]
```

## DESCRIPTION
Return the lab data for the current lab or list all existing labs

## EXAMPLES

### Example 1


```powershell
Import-Lab MyLabName
$LabData = Get-Lab
```

Imports a lab and stores the lab data in the variable LabData

## PARAMETERS

### -List
Indicates whether all existing labs should be listed

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
