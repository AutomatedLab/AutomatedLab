---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Disable-LWAzureAutoShutdown
schema: 2.0.0
---

# Disable-LWAzureAutoShutdown

## SYNOPSIS
Internal worker to disable Azure Auto Shutdown

## SYNTAX

```
Disable-LWAzureAutoShutdown [[-ComputerName] <String[]>] [-Wait] [<CommonParameters>]
```

## DESCRIPTION
Internal worker to disable Azure Auto Shutdown

## EXAMPLES

### Example 1
```powershell
PS C:\> Disable-LWAzureAutoShutdown -ComputerName Host1, Host2 -Wait
```

Disable the Azure auto shutdown by removing the configuration, wait for it to finish

## PARAMETERS

### -ComputerName
List of hosts to disable auto shutdown for

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

### -Wait
Indicates that cmdlet should wait for completion

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

