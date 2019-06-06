---
external help file: PSLog-help.xml
Module Name: PSLog
online version: https://go.microsoft.com/fwlink/?LinkID=113426
schema: 2.0.0
---

# Write-LogEntry

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Write-LogEntry [-Message] <String> [-EntryType] <TraceEventType> [[-Details] <String>] [-SupressConsole]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Details
{{ Fill Details Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EntryType
{{ Fill EntryType Description }}

```yaml
Type: TraceEventType
Parameter Sets: (All)
Aliases:
Accepted values: Critical, Error, Warning, Information, Verbose, Start, Stop, Suspend, Resume, Transfer

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
{{ Fill Message Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SupressConsole
{{ Fill SupressConsole Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
