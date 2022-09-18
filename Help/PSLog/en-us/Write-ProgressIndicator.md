---
external help file: PSLog-help.xml
Module Name: PSLog
online version: https://automatedlab.org/en/latest/PSLog/en-us/Write-ProgressIndicator
schema: 2.0.0
---

# Write-ProgressIndicator

## SYNOPSIS
Write a . to the console, indicating an activity

## SYNTAX

```
Write-ProgressIndicator [<CommonParameters>]
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

