---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-LogFunctionExitWithError

## SYNOPSIS
Logs leaving an advanced function while raising an error.

## SYNTAX

### Message (Default)
```
Write-LogFunctionExitWithError [[-Message] <String>] [[-Details] <String>] [<CommonParameters>]
```

### ErrorRecord
```
Write-LogFunctionExitWithError [[-ErrorRecord] <ErrorRecord>] [[-Details] <String>] [<CommonParameters>]
```

### Exception
```
Write-LogFunctionExitWithError [[-Exception] <Exception>] [[-Details] <String>] [<CommonParameters>]
```

## DESCRIPTION
Logs leaving an advanced function while raising an error.

## EXAMPLES

### Example 1
```powershell
function foo
{
    [CmdletBinding()]
    param
    ()
    
    try
    {
        Enable-WorldDomination -Force -ErrorAction Stop
    }
    catch
    {
        Write-LogFunctionExitWithError -Exception $_.Exception
    }
}
```

Exits the function foo with the Write-Error cmdlet and the rethrown exception

## PARAMETERS

### -Details
Additional error details

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ErrorRecord
An error record to return

```yaml
Type: ErrorRecord
Parameter Sets: ErrorRecord
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exception
An exception to return

```yaml
Type: Exception
Parameter Sets: Exception
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
A message to return as an error

```yaml
Type: String
Parameter Sets: Message
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
