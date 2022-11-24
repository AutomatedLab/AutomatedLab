---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/New-LabAzureResourceGroupDeployment
schema: 2.0.0
---

# New-LabAzureResourceGroupDeployment

## SYNOPSIS
Deploy the lab definition as an Azure resource group

## SYNTAX

```
New-LabAzureResourceGroupDeployment [-Lab] <Lab> [-PassThru] [-Wait] [<CommonParameters>]
```

## DESCRIPTION
Deploy the lab definition as an Azure resource group

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabAzureResourceGroupDeployment -Lab (Get-LabDefinition) -Wait
```

Build current definition on Azure, wait for deployment to finish

## PARAMETERS

### -Lab
Lab definition

```yaml
Type: Lab
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that resulting job or resulting path will be returned

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

### -Wait
Indicates that cmdlet should wait for the deployment to finish

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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

