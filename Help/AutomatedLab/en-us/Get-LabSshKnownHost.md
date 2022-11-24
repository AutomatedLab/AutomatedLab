---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabSshKnownHost
schema: 2.0.0
---

# Get-LabSshKnownHost

## SYNOPSIS
Get content of SSH known host file

## SYNTAX

```
Get-LabSshKnownHost [<CommonParameters>]
```

## DESCRIPTION
Get content of SSH known host file as Objects

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSshKnownHost | Where ComputerName -eq github.com
```

Get all known hosts filtered by ComputerName

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

