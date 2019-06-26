---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAzureResourceGroup

## SYNOPSIS
Get resource groups

## SYNTAX

### ByName (Default)
```
Get-LabAzureResourceGroup [[-ResourceGroupName] <String[]>] [<CommonParameters>]
```

### ByLab
```
Get-LabAzureResourceGroup [-CurrentLab] [<CommonParameters>]
```

## DESCRIPTION
Returns either named Azure resource groups defined in the lab settings or returns all defined resource groups

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureResourceGroup -CurrentLab
```

Returns the Resource Group of the current lab

## PARAMETERS

### -ResourceGroupName
The names of the resource groups to return

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CurrentLab
Indicates that the Resource Group of the current lab should be returned

```yaml
Type: SwitchParameter
Parameter Sets: ByLab
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
