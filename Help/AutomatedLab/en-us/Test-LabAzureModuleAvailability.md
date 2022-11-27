---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Test-LabAzureModuleAvailability
schema: 2.0.0
---

# Test-LabAzureModuleAvailability

## SYNOPSIS
Test if Azure modules are installed and have the required version

## SYNTAX

```
Test-LabAzureModuleAvailability [-AzureStack] [<CommonParameters>]
```

## DESCRIPTION
Test if Azure modules are installed and have the required version.
Check versions using Get-LabConfigurationItem -Name RequiredAzModules or
Get-LabConfigurationItem -Name RequiredAzStackModules if you use Azure Stack.

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabAzureModuleAvailability
```

Boolean indicator if Azure modules are installed in their versions.

## PARAMETERS

### -AzureStack
Indicates that the endpoint is running Azure Stack Hub with its considerably older API versions.

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

### System.Boolean
## NOTES

## RELATED LINKS

