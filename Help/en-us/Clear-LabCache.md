---
external help file: AutomatedLab.Help.xml
Module Name: automatedlab
online version:
schema: 2.0.0
---

# Clear-LabCache

## SYNOPSIS
Clear the lab cache

## SYNTAX

```
Clear-LabCache [<CommonParameters>]
```

## DESCRIPTION
Removes the automated lab cache from the Windows registry: HKEY_CURRENT_USER\Software\AutomatedLab\Cache
Clearing the cache can solve issues with wrong operating systems being detected, or to simply
reset all time stamps that are created.

## EXAMPLES

### Example 1
```powershell
PS C:\> Clear-LabCache -Verbose
```

Clears the AutomatedLab cache for the current user

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
