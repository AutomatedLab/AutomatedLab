---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWVMWareVMStatus
schema: 2.0.0
---

# Get-LWVMWareVMStatus

## SYNOPSIS
Get the power state of a VMWare VM

## SYNTAX

```
Get-LWVMWareVMStatus [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Get the power state of a VMWare VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWVMWareStatus -ComputerName Host1
```

Get the power state of Host1

## PARAMETERS

### -ComputerName
The host name

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

