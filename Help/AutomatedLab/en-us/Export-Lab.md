---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Export-Lab

## SYNOPSIS
Export a lab

## SYNTAX

```
Export-Lab [<CommonParameters>]
```

## DESCRIPTION
Exports a lab including all machine and disk definitions to local XML stores according to the location defined in the lab settings

## EXAMPLES

### Example 1
```powershell
PS C:\> Export-Lab
```

Saves the currently created lab definition to the lab path. Default: $env:PROGRAMDATA\AutomatedLab\Labs

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
