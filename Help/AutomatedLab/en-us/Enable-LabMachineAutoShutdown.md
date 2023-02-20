---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Enable-LabMachineAutoShutdown
schema: 2.0.0
---

# Enable-LabMachineAutoShutdown

## SYNOPSIS
Enable Azure auto-shutdown for machines

## SYNTAX

```
Enable-LabMachineAutoShutdown [[-ComputerName] <String[]>] [-Time] <TimeSpan> [-TimeZone <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Enable Azure auto-shutdown for machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabMachineAutoShutdown -Time '19:00:00'
```

Using the current time zone, shut down all lab VMs at 7 pm

## PARAMETERS

### -ComputerName
List of machines to stop

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
Time at which machines are stopped

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeZone
Timezone of shutdown time, refer to Get-TimeZone

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

