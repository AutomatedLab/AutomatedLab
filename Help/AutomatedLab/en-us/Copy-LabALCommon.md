---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Copy-LabALCommon
schema: 2.0.0
---

# Copy-LabALCommon

## SYNOPSIS
Copy AutomatedLab.Common to lab machine

## SYNTAX

```
Copy-LabALCommon [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Copy AutomatedLab.Common to lab machine

## EXAMPLES

### Example 1
```powershell
PS C:\> Copy-LabALCommon -ComputerName Host1, Host2
```

Copy module AutomatedLab.Common to lab machines Host1 and host2

## PARAMETERS

### -ComputerName
List of machines in the lab

```yaml
Type: String[]
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

