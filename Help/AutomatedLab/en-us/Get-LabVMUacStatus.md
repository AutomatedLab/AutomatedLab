---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMUacStatus

## SYNOPSIS
Get the UAC status of a machine

## SYNTAX

```
Get-LabVMUacStatus [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Retrieves the status of the User Account Control of one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMUacStatus -ComputerName DC01,DC02
```

Retrieves the status of the User Account Control on DC01 and DC02

## PARAMETERS

### -ComputerName
The computer names

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

## OUTPUTS

## NOTES

## RELATED LINKS
