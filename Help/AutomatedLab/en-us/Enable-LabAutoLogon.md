---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Enable-LabAutoLogon

## SYNOPSIS
Enable the automatic logon of a Windows account

## SYNTAX

```
Enable-LabAutoLogon [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Enable the automatic logon of a Windows account

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabAutoLogon -ComputerName SQL01
```

Enable the automatic logon on SQL01 with the lab installation account (or domain admin account).
Useful for Installations that require a user session

## PARAMETERS

### -ComputerName
The hosts to enable auto logon on

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
