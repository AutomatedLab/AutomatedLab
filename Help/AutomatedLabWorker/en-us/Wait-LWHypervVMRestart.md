---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Wait-LWHypervVMRestart
schema: 2.0.0
---

# Wait-LWHypervVMRestart

## SYNOPSIS
Wait for the restart of a Hyper-V VM

## SYNTAX

```
Wait-LWHypervVMRestart [-ComputerName] <String[]> [[-TimeoutInMinutes] <Double>] [[-ProgressIndicator] <Int32>]
 [[-StartMachinesWhileWaiting] <Machine[]>] [[-MonitorJob] <Job[]>] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Monitors the uptime of a VM to wait for it to restart

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LWHypervVMRestart -ComputerName host1,host2 -TimeoutInMinutes 10
```

Wait 10 minutes for a restart of host1 and host2, for example because of a pending installation.

## PARAMETERS

### -ComputerName
The machine to restart

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

### -MonitorJob
Keep monitoring on or more jobs until the timeout is reached or the uptime of the VM is reset

```yaml
Type: Job[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressIndicator
Interval in seconds that a .
should be written to the console

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

### -StartMachinesWhileWaiting
Indicates that other machines can be started while waiting for this machine to restart

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

