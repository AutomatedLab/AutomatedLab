---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Stop-LWHypervVM

## SYNOPSIS
Stop a Hyper-V VM

## SYNTAX

```
Stop-LWHypervVM [-ComputerName] <String[]> [[-TimeoutInMinutes] <Double>] [[-ProgressIndicator] <Int32>]
 [-NoNewLine] [-ShutdownFromOperatingSystem] [<CommonParameters>]
```

## DESCRIPTION
Stop a Hyper-V VM, with the ability to wait for a timeout in minutes. Both Windows and Linux
support a shutdown from the OS, if they are available via WinRM

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-LWHypervVM -ComputerName SAPHANA -TimeoutInMinutes 20
```

Wait for a busy system to shut down for up to 20 minutes.

## PARAMETERS

### -ComputerName
The machines to stop

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

### -ShutdownFromOperatingSystem
Initiate the shutdown from the operating system. Uses shutdown.exe on Windows or /bin/shutdown on Linux

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

### -TimeoutInMinutes
The maximum timeout to wait for a proper VM shutdown

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
