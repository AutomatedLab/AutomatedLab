---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabCache

## SYNOPSIS
Get the content of the lab cache

## SYNTAX

```
Get-LabCache [<CommonParameters>]
```

## DESCRIPTION
Get the content of the lab cache that is stored as XML in the registry

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabCache
```

Gets the timestamp and XML content of each cache in HKCU:\Software\AutomatedLab\Cache

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
