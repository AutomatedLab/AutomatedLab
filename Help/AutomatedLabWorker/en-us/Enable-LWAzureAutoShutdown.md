---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Enable-LWAzureAutoShutdown
schema: 2.0.0
---

# Enable-LWAzureAutoShutdown

## SYNOPSIS
Internal worker to enable Azure Auto Shutdown

## SYNTAX

```
Enable-LWAzureAutoShutdown [[-ComputerName] <String[]>] [[-Time] <TimeSpan>] [[-TimeZone] <String>] [-Wait]
 [<CommonParameters>]
```

## DESCRIPTION
Internal worker to enable Azure Auto Shutdown

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LWAzureAutoShutdown -ComputerName host1, host2 -Time '19:00:00' -TimeZone 'UTC' -Wait
```

On host1 and host2 configure the auto shutdown to take place at 19:00:00 (or 7pm) in the UTC time zone.

## PARAMETERS

### -ComputerName
List of lab machines to configure auto shutdown for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Time
The time to shut down the machine as timespan, e.g. '19:00:00'

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeZone
The time zone effective for the Time parameter. Use Get-TimeZone as reference.

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

### -Wait
Indicates that cmdlet waits for completion

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

