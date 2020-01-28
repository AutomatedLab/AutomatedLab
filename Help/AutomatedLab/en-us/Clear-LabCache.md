---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
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

## EXAMPLES

### Example 1
```powershell
PS C:\> Clear-LabCache
```

Clears all of AutomatedLab's caches, meaning that all timestamps and the cached ISOs will be removed. During
the next lab installation, the caches will be updated again. Useful when running into issues with the available
operating systems.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
