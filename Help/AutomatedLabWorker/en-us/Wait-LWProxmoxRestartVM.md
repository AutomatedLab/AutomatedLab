---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Wait-LWProxmoxRestartVM
schema: 2.0.0
---

# Wait-LWProxmoxRestartVM

## SYNOPSIS

Waits for Proxmox virtual machines to restart

## SYNTAX

```
Wait-LWProxmoxRestartVM [-ComputerName] <String[]> [[-TimeoutInMinutes] <Double>] [[-ProgressIndicator] <Int32>] [-MonitoringStartTime] <DateTime> [[-MonitorJob] <Job[]>] [[-StartMachinesWhileWaiting] <Machine[]>] [-DoNotUseCredSsp] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION

Monitors Proxmox virtual machines and waits for them to complete a restart operation. Checks boot time to verify the restart occurred after the specified monitoring start time.

## EXAMPLES

### Example 1

```powershell
$startTime = Get-Date
Restart-LabVM -ComputerName DC01
Wait-LWProxmoxRestartVM -ComputerName DC01 -MonitoringStartTime $startTime
```

Waits for DC01 to restart after a specific time

### Example 2

```powershell
Wait-LWProxmoxRestartVM -ComputerName DC01,SQL01 -MonitoringStartTime (Get-Date) -TimeoutInMinutes 10
```

Waits up to 10 minutes for multiple VMs to restart

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to monitor for restart

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

### -TimeoutInMinutes

Maximum time to wait for VMs to restart (in minutes). Default is 15 minutes.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 15
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressIndicator

Interval for progress indication

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

### -MonitoringStartTime

The time when monitoring started. VMs must have booted after this time to be considered restarted.

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

### -DoNotUseCredSsp

Do not use CredSSP for authentication

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

### -NoNewLine

Suppress new line in output

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

### -MonitorJob

Keep monitoring one or more jobs until the timeout is reached or all VMs have restarted. Failed jobs are inspected for AL_CRITICAL or AL_ERROR markers.

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

### -StartMachinesWhileWaiting

Indicates that other machines can be started while waiting for the monitored machines to restart

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
