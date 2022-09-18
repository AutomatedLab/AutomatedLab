---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabAzureAvailableRoleSize
schema: 2.0.0
---

# Get-LabAzureAvailableRoleSize

## SYNOPSIS
Get all available Azure Compute sizes

## SYNTAX

### DisplayName (Default)
```
Get-LabAzureAvailableRoleSize -DisplayName <String> [<CommonParameters>]
```

### Name
```
Get-LabAzureAvailableRoleSize -LocationName <String> [<CommonParameters>]
```

## DESCRIPTION
Get all available Azure Compute sizes

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureAvailableRoleSize -Location 'west europe'
```

List all sizes we can deploy in West Europe

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

