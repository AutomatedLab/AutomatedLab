---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Disable-LabMachineAutoShutdown
schema: 2.0.0
---

# Disable-LabMachineAutoShutdown

## SYNOPSIS
Disable Azure auto-shutdown for machines

## SYNTAX

```
Disable-LabMachineAutoShutdown [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Disable Azure auto-shutdown for machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Disable-LabMachineAutoShutdown
```

Clears all shutdown schedules for all machines

## PARAMETERS

### -ComputerName
List of AutomatedLab VMs to clear schedule for

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

