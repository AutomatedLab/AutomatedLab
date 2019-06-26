---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Start-LWAzureVM

## SYNOPSIS
Start Azure VMs

## SYNTAX

```
Start-LWAzureVM [-ComputerName] <String[]> [[-DelayBetweenComputers] <Int32>] [[-ProgressIndicator] <Int32>]
 [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Start Azure VMs in parallel or staggered, with or without progress indicators

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-LWAzureVM -ComputerName (Get-LabVm) -DelayBetweenComputers 5
```

Start all Azure lab VMs with a five minute delay between each

## PARAMETERS

### -ComputerName
The machines to start

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
The delay in minutes between the start of each machine

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
