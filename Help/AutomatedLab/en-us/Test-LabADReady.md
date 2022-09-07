---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Test-LabADReady
schema: 2.0.0
---

# Test-LabADReady

## SYNOPSIS
Test if lab ADWS are ready for scripting

## SYNTAX

```
Test-LabADReady [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Test if lab ADWS are ready for scripting

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabADReady -ComputerName DC1
```

Test if lab ADWS are ready on DC1 for scripting

## PARAMETERS

### -ComputerName
The name of a lab domain controller

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

