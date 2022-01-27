---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAzureAvailableSku

## SYNOPSIS
List all available operating systems on Azure

## SYNTAX

```
Get-LabAzureAvailableSku [-Location] <String> [<CommonParameters>]
```

## DESCRIPTION
List all available operating systems on Azure

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureAvailableSku -Location 'West Europe'
```

List all available Operating Systems for AutomatedLab in West Europ

## PARAMETERS

### -Location
Location display name

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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
