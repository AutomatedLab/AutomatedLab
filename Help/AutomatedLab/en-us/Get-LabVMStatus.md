---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMStatus

## SYNOPSIS
Gets the power state of lab machines

## SYNTAX

```
Get-LabVMStatus [[-ComputerName] <String[]>] [-AsHashTable] [<CommonParameters>]
```

## DESCRIPTION
Gets the power state of lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMStatus
```

Returns the status of al lab VMs

## PARAMETERS

### -AsHashTable
Convert the result into a hashtable with the machine names as keys

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

### -ComputerName
The machines to get the status from

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
