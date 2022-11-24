---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Test-LabAutoLogon
schema: 2.0.0
---

# Test-LabAutoLogon

## SYNOPSIS
Test if the autologon settings are correct

## SYNTAX

```
Test-LabAutoLogon [-ComputerName] <String[]> [-TestInteractiveLogonSession] [<CommonParameters>]
```

## DESCRIPTION
Test if the autologon settings are correct

## EXAMPLES

### Example 1
```powershell
PS C:\> if (-not (Test-LabAutoLogon SQL01)) {Enable-LabAutoLogon SQL01}
```

If auto logon is not configured, configure it for SQL01

## PARAMETERS

### -ComputerName
The hosts to test auto logon on

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

### -TestInteractiveLogonSession
Indicates that the cmdlet should test if there is an interactive logon session.
Useful to test before Installations that require an interactive context.

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

