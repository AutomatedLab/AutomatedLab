---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Start-LWProxmoxVM
schema: 2.0.0
---

# Start-LWProxmoxVM

## SYNOPSIS

Starts Proxmox virtual machines

## SYNTAX

```
Start-LWProxmoxVM [-ComputerName] <String[]> [[-DelayBetweenComputers] <Int32>] [[-PreDelaySeconds] <Int32>] [[-PostDelaySeconds] <Int32>] [[-ProgressIndicator] <Int32>] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION

Starts one or more Proxmox virtual machines. Supports delays between starts and progress indication.

## EXAMPLES

### Example 1

```powershell
Start-LWProxmoxVM -ComputerName DC01
```

Starts the DC01 virtual machine

### Example 2

```powershell
Start-LWProxmoxVM -ComputerName DC01,SQL01 -DelayBetweenComputers 10
```

Starts multiple VMs with a 10-second delay between each start

### Example 3

```powershell
Start-LWProxmoxVM -ComputerName WEB01 -PreDelaySeconds 5 -PostDelaySeconds 30
```

Starts a VM with pre and post delays

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to start

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

### -DelayBetweenComputers

Delay in seconds between starting each computer

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreDelaySeconds

Delay in seconds before starting any computers

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostDelaySeconds

Delay in seconds after starting all computers

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
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
Position: 4
Default value: None
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
