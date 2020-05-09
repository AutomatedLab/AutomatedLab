---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabAzureDefaultLocation

## SYNOPSIS
Set Azure location

## SYNTAX

```
Set-LabAzureDefaultLocation [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Sets the default location for all Azure-based lab commands

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabAzureDefaultLocation -Name westeurope
```

Set the location for all Az cmdlets to westeurope, where applicable

## PARAMETERS

### -Name
The location display name, e.g.
'West US'

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
