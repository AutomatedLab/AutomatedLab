---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Wait-LWVMWareRestartVM

## SYNOPSIS
Wait for the restart of a VMWare VM

## SYNTAX

```
Wait-LWVMWareRestartVM [-ComputerName] <String[]> [[-TimeoutInMinutes] <Double>] [<CommonParameters>]
```

## DESCRIPTION
Wait for the restart of a VMWare VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LWVMWareRestartVM -ComputerName DC01 -Timeout 12.5
```

Wait 12:30 for DC01 to reboot

## PARAMETERS

### -ComputerName
The hosts to wait for

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

### -TimeoutInMinutes
The timeout to wait in minutes

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
