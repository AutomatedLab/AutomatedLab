---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-LabAzureResourceGroup

## SYNOPSIS
Remove a resource group

## SYNTAX

```
Remove-LabAzureResourceGroup [-ResourceGroupName] <String[]> [-Force] [<CommonParameters>]
```

## DESCRIPTION
Removes one or more resource groups from Azure and from the lab cache

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabAzureResourceGroup -ResourceGroupName MyLab
```

Removes the resource group MyLab - usually only used in Remove-Lab

## PARAMETERS

### -ResourceGroupName
The resource group names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Force
Indicates that the resource groups should be forcibly removed

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
