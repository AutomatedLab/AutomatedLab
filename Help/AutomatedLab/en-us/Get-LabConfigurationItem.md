---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabConfigurationItem

## SYNOPSIS
Get AutomatedLab settings

## SYNTAX

```
Get-LabConfigurationItem [[-Name] <String>] [[-Default] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Get-LabConfigurationItem is a wrapper to retrieve configuration settings through PSFramework (before that: Datum)

It is used mostly internally to get specific settings like the default lab VM restart timeout.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabConfigurationItem -Name Timeout_RestartLabMachine_Shutdown
```

Returns the configured timeout for the shutdown during Restart-LabVM. Default is 30, but can be configured with the PSFramework module

## PARAMETERS

### -Default
A default value that should be returned in case there is no such setting

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

### -Name
The name of the setting, e.g. Timeout_RestartLabMachine_Shutdown

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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
