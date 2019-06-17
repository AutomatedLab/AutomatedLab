---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Write-ScreenInfo

## SYNOPSIS
Write formatted text on screen

## SYNTAX

```
Write-ScreenInfo [[-Message] <String[]>] [[-TimeDelta] <TimeSpan>] [[-TimeDelta2] <TimeSpan>] [-Type <String>]
 [-NoNewLine] [-TaskStart] [-TaskEnd] [-OverrideNoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Write formatted text on screen. Using TimeDelta and TimeDelta2 you can indicate the runtime of a process or
an operation. With the parameters TaskStart and TaskEnd you can control the indentation.

## EXAMPLES

### Example 1
```powershell
Write-ScreenInfo -Message 'So it begins...' -TaskStart
Write-ScreenInfo -Message 'So it continues...'
Write-ScreenInfo -Message 'So it ends...' -TaskEnd
Write-ScreenInfo -Message 'Intendation normal'
```

Returns the following:
15:36:20|00:00:04|00:00:00.000| So it begins...
15:36:20|00:00:04|00:00:00.005| - So it continues...
15:36:20|00:00:04|00:00:00.011| - So it ends...
15:36:20|00:00:04|00:00:03.235| Intendation normal

## PARAMETERS

### -Message
The message to be displayed

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoNewLine
Do not add a new line after the output

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverrideNoDisplay
Override the NoDisplay parameter of the calling cmdlet

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TaskEnd
Indicates that the indentation will return back to the previous value

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TaskStart
Indicates that the indentation should be increased.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeDelta
Controls the first timespan that is displayed after the current time. Calculated automatically

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeDelta2
Controls the second timespan that is displayed after the current time. Calculated automatically

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
The type of the message. Default is Info

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Error, Warning, Info, Verbose, Debug

Required: False
Position: Named
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
