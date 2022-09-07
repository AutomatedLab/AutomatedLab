---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Disable-LabTelemetry
schema: 2.0.0
---

# Disable-LabTelemetry

## SYNOPSIS
Disable the transmission of telemetry

## SYNTAX

```
Disable-LabTelemetry [<CommonParameters>]
```

## DESCRIPTION
Disable the transmission of telemetry by setting the environment variable AUTOMATEDLAB_TELEMETRY_OPTOUT to 1

## EXAMPLES

### Example 1
```powershell
PS C:\> Disable-LabTelemetry
```

Disable telemetry until Enable-LabTelemetry is used.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

