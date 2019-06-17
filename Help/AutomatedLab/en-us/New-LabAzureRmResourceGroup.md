---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabAzureRmResourceGroup

## SYNOPSIS
Wrapper to create a new resource group and include it in the lab metadata

## SYNTAX

```
New-LabAzureRmResourceGroup [-ResourceGroupNames] <String[]> [-LocationName] <String> [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Wrapper to create a new resource group and include it in the lab metadata

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabAzureRmResourceGroup -ResourceGroupNames a,b,c -LocationName 'westeurope'
```

Create three new resource groups in West Europe

## PARAMETERS

### -ResourceGroupNames
Resource groups to create

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocationName
Location to create resource in 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the cmdlet returns data

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

## OUTPUTS

## NOTES

## RELATED LINKS
