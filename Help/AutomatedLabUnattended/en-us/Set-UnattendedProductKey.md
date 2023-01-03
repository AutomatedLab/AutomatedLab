---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedProductKey
schema: 2.0.0
---

# Set-UnattendedProductKey

## SYNOPSIS
Set the Windows product key.

## SYNTAX

```
Set-UnattendedProductKey [-ProductKey] <String> [<CommonParameters>]
```

## DESCRIPTION
Set the Windows product key.
Currently not supported on Linux, but in a future release will configure the enterprise distributions RHEL and SLES.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedProductKey -ProductKey FCKGW-YouKnowTheRest
```

{{ Add example description here }}

## PARAMETERS

### -ProductKey
The product key to set

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

