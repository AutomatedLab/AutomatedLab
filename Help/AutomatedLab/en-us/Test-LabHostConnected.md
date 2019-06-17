---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Test-LabHostConnected

## SYNOPSIS
Test if the lab host is connected

## SYNTAX

```
Test-LabHostConnected [-Throw] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION
Test if the lab host is connected. Optionally throws an exception

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabHostConnected -Throw
```

If the host is not connected to the internet, throws a terminating error

## PARAMETERS

### -Quiet
Do not return any data

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Throw
Throw an exception if host is not connected

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
