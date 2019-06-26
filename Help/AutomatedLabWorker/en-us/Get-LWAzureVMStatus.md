---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureVMStatus

## SYNOPSIS
Returns the power state of a lab's Azure VMs

## SYNTAX

```
Get-LWAzureVMStatus [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Returns the power state of a lab's Azure VMs

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureVMStatus -ComputerName HostA,HostB
```

Returns the power state of HostA and HostB

## PARAMETERS

### -ComputerName
The machine names to get the power state from

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
