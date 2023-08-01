---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Restart-ServiceResilient
schema: 2.0.0
---

# Restart-ServiceResilient

## SYNOPSIS
Restart a service

## SYNTAX

```
Restart-ServiceResilient [[-ComputerName] <String[]>] [[-ServiceName] <Object>] [-NoNewLine]
 [<CommonParameters>]
```

## DESCRIPTION
Reliably restarts one or more services by utilising a retry count and properly observing dependencies

## EXAMPLES

### Example 1
```powershell
PS C:\> Restart-ServiceResilient -ComputerName POSHFS1 -ServiceName Spooler
```

Restart spooler service on POSHFS1

## PARAMETERS

### -ComputerName
The computer names

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

### -NoNewLine
Indicates that no new lines should be present in the output

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceName
The service to restart

```yaml
Type: Object
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

## OUTPUTS

## NOTES

## RELATED LINKS

