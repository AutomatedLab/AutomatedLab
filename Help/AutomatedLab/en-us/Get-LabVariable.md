---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabVariable
schema: 2.0.0
---

# Get-LabVariable

## SYNOPSIS
Get lab variables

## SYNTAX

```
Get-LabVariable [<CommonParameters>]
```

## DESCRIPTION
Gets all defined variables in the global scope matching the name pattern 'AL_(\[a-zA-Z0-9\]{8})+\[-.\]+(\[a-zA-Z0-9\]{4})+\[-.\]+(\[a-zA-Z0-9\]{4})+\[-.\]+(\[a-zA-Z0-9\]{4})+\[-.\]+(\[a-zA-Z0-9\]{12})'

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVariable
```

Returns all runtime variables starting with AL_

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

