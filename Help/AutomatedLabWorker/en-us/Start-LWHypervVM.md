---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Start-LWHypervVM

## SYNOPSIS
Start a Hyper-V VM

## SYNTAX

```
Start-LWHypervVM [-ComputerName] <String[]> [[-DelayBetweenComputers] <Int32>] [[-PreDelaySeconds] <Int32>]
 [[-PostDelaySeconds] <Int32>] [[-ProgressIndicator] <Int32>] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Start a Hyper-V VM with optional delays before, after and between starts.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-LWHypervVM -ComputerName CLU01,CLU02 -PostDelaySeconds 10
```

Start the VMs CLU01 and CLU02 with a post delay of 10 seconds

## PARAMETERS

### -ComputerName
The host to start

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
The delay between starts in minutes

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

### -PostDelaySeconds
The delay after a machine has started in seconds

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreDelaySeconds
The delay before a machine has started in seconds

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

### -ProgressIndicator
Interval in seconds that a . should be written to the console

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
