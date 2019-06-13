---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-ProgressIndicatorEnd

## SYNOPSIS
Write a . with line break

## SYNTAX

```
Write-ProgressIndicatorEnd
```

## DESCRIPTION
Write a . with line break

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

After outputting . in a loop, will output . including a line break

## PARAMETERS

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
