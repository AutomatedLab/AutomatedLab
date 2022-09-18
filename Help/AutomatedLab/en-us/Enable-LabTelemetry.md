---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Enable-LabTelemetry
schema: 2.0.0
---

# Enable-LabTelemetry

## SYNOPSIS
Enable the transmission of telemetry

## SYNTAX

```
Enable-LabTelemetry [<CommonParameters>]
```

## DESCRIPTION
Enable the transmission of telemetry by setting AUTOMATEDLAB_TELEMETRY_OPTOUT to 0

The full report can be accessed at <https://app.powerbi.com/view?r=eyJrIjoiMmYyYTdmODUtMDJlZS00M2QwLWE1MDgtMGU5YTkyODVhZmQ2IiwidCI6Ijc5MzlmZDI1LTQ0YjktNGNjMC04YjVkLWRmZGZjYTg2ZTZlYyIsImMiOjl9>

The following information will be collected - Your country (IP addresses are by default set to 0.0.0.0 by Azure Application Insights after the location is extracted)

- Your number of lab machines
- The roles you used (including custom roles, so be careful with your naming pattern)
- The time it took your lab to finish
- The lifetime of your lab (collected once Remove-Lab is executed)
- Your AutomatedLab version, the PS Version, OS Version and the lab's Hypervisor type

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabTelemetry
```

Enables telemetry

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

