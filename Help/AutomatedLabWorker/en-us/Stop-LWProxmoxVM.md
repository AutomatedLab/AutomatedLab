---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Stop-LWProxmoxVM
schema: 2.0.0
---

# Stop-LWProxmoxVM

## SYNOPSIS

Stops Proxmox virtual machines

## SYNTAX

```
Stop-LWProxmoxVM [-ComputerName] <String[]> [[-TimeoutInMinutes] <Double>] [[-ProgressIndicator] <Int32>] [[-ShutdownFromOperatingSystem] <Boolean>] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION

Stops one or more Proxmox virtual machines. Can perform graceful shutdown from within the OS or force stop.

## EXAMPLES

### Example 1

```powershell
Stop-LWProxmoxVM -ComputerName DC01
```

Gracefully stops the DC01 virtual machine

### Example 2

```powershell
Stop-LWProxmoxVM -ComputerName DC01,SQL01 -ShutdownFromOperatingSystem $false
```

Force stops multiple VMs without OS shutdown

### Example 3

```powershell
Stop-LWProxmoxVM -ComputerName WEB01 -TimeoutInMinutes 5
```

Stops a VM with a 5-minute timeout

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to stop

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

Maximum time to wait for VMs to stop (in minutes)

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

### -ShutdownFromOperatingSystem

Whether to gracefully shut down from within the OS (true) or force stop (false)

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
