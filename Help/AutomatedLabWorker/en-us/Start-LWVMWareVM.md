---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Start-LWVMWareVM

## SYNOPSIS
Start a VMWare VM

## SYNTAX

```
Start-LWVMWareVM [-ComputerName] <String[]> [[-DelayBetweenComputers] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Start a VMWare VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-LWVMWareVM Host1,Host2
```

Start Host1 and Host2 in parallel

## PARAMETERS

### -ComputerName
The hosts to start

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

### -DelayBetweenComputers
The delay in minutes between each start

```yaml
Type: Int32
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
