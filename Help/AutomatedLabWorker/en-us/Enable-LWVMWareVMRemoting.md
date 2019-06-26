---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Enable-LWVMWareVMRemoting

## SYNOPSIS
Enable CredSSP on a VMWare VM

## SYNTAX

```
Enable-LWVMWareVMRemoting [-ComputerName] <Object> [<CommonParameters>]
```

## DESCRIPTION
Enable CredSSP on a VMWare VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LWVMWareVMRemoting -ComputerName SomeServer01
```

Configures CredSSP on SomeServer01

## PARAMETERS

### -ComputerName
The machines to enable CredSSP on

```yaml
Type: Object
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
