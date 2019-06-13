---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-LogError

## SYNOPSIS
Log an exception with the ability to add more details

## SYNTAX

### Name (Default)
```
Write-LogError [[-Details] <String>] [-Exception <Exception>] [<CommonParameters>]
```

### Message
```
Write-LogError [-Message] <String> [[-Details] <String>] [-Exception <Exception>] [<CommonParameters>]
```

## DESCRIPTION
Logs an error to the log buffer

## EXAMPLES

### Example 1
```powershell
PS C:\> Write-LogError -Message 'Bad things happen'
```

Log the message Bad things happen as an error

## PARAMETERS

### -Details
Additional details for an exception

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

### -Exception
An exception object

```yaml
Type: Exception
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
The message to log

```yaml
Type: String
Parameter Sets: Message
Aliases:

Required: True
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
