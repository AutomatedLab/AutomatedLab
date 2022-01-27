---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAzureAvailableRoleSize

## SYNOPSIS
Get all available Azure Compute sizes

## SYNTAX

```
Get-LabAzureAvailableRoleSize [-Location] <String> [<CommonParameters>]
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
