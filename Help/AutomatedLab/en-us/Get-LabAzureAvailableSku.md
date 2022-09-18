---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabAzureAvailableSku
schema: 2.0.0
---

# Get-LabAzureAvailableSku

## SYNOPSIS
List all available operating systems on Azure

## SYNTAX

### DisplayName (Default)
```
Get-LabAzureAvailableSku -DisplayName <String> [<CommonParameters>]
```

### Name
```
Get-LabAzureAvailableSku -LocationName <String> [<CommonParameters>]
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

### -DisplayName
Location display name

```yaml
Type: String
Parameter Sets: DisplayName
Aliases: Location

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocationName
Location name

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: Named
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

