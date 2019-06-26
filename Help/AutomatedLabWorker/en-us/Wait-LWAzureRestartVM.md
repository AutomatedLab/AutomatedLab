---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Wait-LWAzureRestartVM

## SYNOPSIS
Wait for the restart of an Azure VM

## SYNTAX

```
Wait-LWAzureRestartVM [-ComputerName] <String[]> [-DoNotUseCredSsp] [[-TimeoutInMinutes] <Double>]
 [[-ProgressIndicator] <Int32>] [-NoNewLine] [-MonitoringStartTime] <DateTime> [<CommonParameters>]
```

## DESCRIPTION
Use the event log to watch for a reboot event of the Azure VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LWAzureRestartVM -ComputerName SQL01 -MonitoringStartTime (Get-Date).AddMinutes(15) -Timeout 30
```

Start in 15 minutes to watch for a reboot of SQL01, for a maximum time of 30 minutes

## PARAMETERS

### -ComputerName
The machine to wait for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseCredSsp
Indicates that CredSSP should not be used to connect

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

### -MonitoringStartTime
When does monitoring of the event log start?

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoNewLine
Indicates that no line break should be emitted after the console output

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

### -ProgressIndicator
Interval in seconds that a . should be written to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutInMinutes
The timeout in minutes to wait for the restart of the machine

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
