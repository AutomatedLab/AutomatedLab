---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Stop-LWAzureVM

## SYNOPSIS
Stop an Azure VM

## SYNTAX

```
Stop-LWAzureVM [-ComputerName] <String[]> [[-ProgressIndicator] <Int32>] [-NoNewLine]
 [-ShutdownFromOperatingSystem] [[-StayProvisioned] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Stop an Azure VM, with the option to keep the VM provisioned

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-LWAzureVM -ComputerName (Get-LabVm) -StayProvisioned
```

Shut down all lab VMs while keeping their resources provisioned for a faster
start next time.

## PARAMETERS

### -ComputerName
The hosts to stop

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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShutdownFromOperatingSystem
Initiate the shutdown from the operating system instead of using Stop-AzVm

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

### -StayProvisioned
Indicates that the VM should stay provisioned

```yaml
Type: Boolean
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
