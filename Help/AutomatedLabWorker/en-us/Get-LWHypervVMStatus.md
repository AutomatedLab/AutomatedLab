---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWHypervVMStatus

## SYNOPSIS
Get the power state of a Hyper-V VM

## SYNTAX

```
Get-LWHypervVMStatus [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Get the power state of a Hyper-V VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervVMStatus -ComputerName DSCDC01
```

Returns the VM state of DSCDC01

## PARAMETERS

### -ComputerName
The host name to get the power state from

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
