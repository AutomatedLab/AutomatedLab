---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-ProgressIndicator

## SYNOPSIS
Write a . to the console, indicating an activity

## SYNTAX

```
Write-ProgressIndicator
```

## DESCRIPTION
Write a . to the console, indicating an activity

## EXAMPLES

### Example 1
```powershell
function foo
{
    [CmdletBinding()]
    param
    ()
    
    foreach ($thing in $things)
    {
        #Long running operation. Need to have output.
        Write-ProgressIndicator
        sleep 120
    }
    Write-ProgressIndicatorEnd
}
```

Write . to the console host as long as loop is processing

## PARAMETERS

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
