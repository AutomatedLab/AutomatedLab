---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Stop-LWVMWareVM

## SYNOPSIS
Stop a VMWare VM

## SYNTAX

```
Stop-LWVMWareVM [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Stop a VMWare VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-LWVMWareVM -ComputerName (Get-LabVM)
```

Stops all VMWare VMs in the lab

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
