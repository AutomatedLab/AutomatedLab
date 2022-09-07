---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabMachineAutoShutdown
schema: 2.0.0
---

# Get-LabMachineAutoShutdown

## SYNOPSIS
Get Azure auto shutdown config for entire lab

## SYNTAX

```
Get-LabMachineAutoShutdown [<CommonParameters>]
```

## DESCRIPTION
Get Azure auto shutdown config for entire lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabMachineAutoShutdown
```

ComputerName Time     TimeZone                                                    
------------ ----     --------                                                    
DFS-DC1      18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
DFS-FS-A     18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
DFS-FS-B     18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
DFS-FS-C     18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
DFS-NS-A     18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
DFS-NS-B     18:00:00 (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

