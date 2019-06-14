---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Save-LWHypervVM

## SYNOPSIS
Save the state of a Hyper-V VM

## SYNTAX

```
Save-LWHypervVM [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Save the state of a Hyper-V VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Save-LWHypervVM -ComputerName (Get-LabVm)
```

Saves all lab VMs

## PARAMETERS

### -ComputerName
The machines to save

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
