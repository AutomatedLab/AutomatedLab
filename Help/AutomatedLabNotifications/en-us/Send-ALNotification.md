---
external help file: AutomatedLabNotifications-help.xml
Module Name: AutomatedLabNotifications
online version:
schema: 2.0.0
---

# Send-ALNotification

## SYNOPSIS
Send a notification to a provider

## SYNTAX

```
Send-ALNotification [-Activity] <String> [-Message] <String> [-Provider] <String> [<CommonParameters>]
```

## DESCRIPTION
Send a notification to a provider. The lab data is retrieved automatically, and activity and message are simply
posted to the provider.

## EXAMPLES

### Example 1
```powershell
PS C:\> Send-ALNotification -Activity 'Doing stuff' -Message 'Doing it really well.' -Provider Mail
```

Sends a mail

## PARAMETERS

### -Activity
The activity that was executed, e.g. Lab started

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

### -Message
The message, e.g. Lab finished with 0 errors

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Provider
The provider to use. Uses a dynamic ValidateSet over all possible providers.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
