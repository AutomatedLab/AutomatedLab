---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Disable-LabAutoLogon

## SYNOPSIS
Disable the automatic logon of a Windows account

## SYNTAX

```
Disable-LabAutoLogon [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Disable the automatic logon of a Windows account

## EXAMPLES

### Example 1
```powershell
PS C:\> Disable-LabAutoLogon -ComputerName DC01,DC02
```

Disables the automatic logon on DC01 and DC02

## PARAMETERS

### -ComputerName
The hosts to disable autologon on

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
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
