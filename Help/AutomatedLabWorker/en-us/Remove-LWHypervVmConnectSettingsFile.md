---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWHypervVmConnectSettingsFile
schema: 2.0.0
---

# Remove-LWHypervVmConnectSettingsFile

## SYNOPSIS

Removes the VMConnect config file to the given Hyper-V VM.

## SYNTAX

```
Remove-LWHypervVmConnectSettingsFile [-ComputerName] <string>  [<CommonParameters>]
```

## DESCRIPTION

Removes the VMConnect config file to the given Hyper-V VM.

## EXAMPLES

### Example 1

```powershell
PS C:\> Remove-LWHypervVmConnectSettingsFile -ComputerName Server1
```

Removes VMConnect config file for Hyper-V VM Server1.

## PARAMETERS

### -ComputerName
The name of the machine to remove the config file for.

```yaml
Type: String
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
