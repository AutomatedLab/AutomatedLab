---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-LogFunctionExit

## SYNOPSIS
Logs leaving an advanced function.

## SYNTAX

```
Write-LogFunctionExit [[-ReturnValue] <String>] [<CommonParameters>]
```

## DESCRIPTION
Logs leaving an advanced function.

## EXAMPLES

### Example 1
```powershell
function foo
{
    [CmdletBinding()]
    param
    ()
    
    Write-LogFunctionExit
}
foo -Verbose
```

Will log a verbose function exit whenever foo is executed. Output would be:
`VERBOSE: foo...leaving...(Time elapsed: 00:00:00:005)`

## PARAMETERS

### -ReturnValue
Optionally add a return value

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
