---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-LogFunctionEntry

## SYNOPSIS
Log entering a function

## SYNTAX

```
Write-LogFunctionEntry [<CommonParameters>]
```

## DESCRIPTION
Logs entering of an advanced function. Logs all parameters as well

## EXAMPLES

### Example 1
```powershell
function foo
{
    [CmdletBinding()]
    param
    ()
    
    Write-LogFunctionEntry
}
foo -Verbose
```

Will log a verbose function entry whenever foo is executed. Output would be:
`VERBOSE: foo Entering... (Verbose=True)`

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
