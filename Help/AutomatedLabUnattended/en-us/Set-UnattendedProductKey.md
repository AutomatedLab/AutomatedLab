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

### Windows (Default)
```
Set-UnattendedProductKey -ProductKey <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedProductKey -ProductKey <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedProductKey -ProductKey <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedProductKey -ProductKey <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the Windows product key.
Currently not supported on Linux, but in a future release will configure the enterprise distributions RHEL and SLES.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedProductKey -ProductKey FCKGW-YouKnowTheRest
```

Set product key in unattended XML template

## PARAMETERS

### -IsAutoYast
Indicates that this setting is placed in an AutoYAST file

```yaml
Type: SwitchParameter
Parameter Sets: Yast
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsCloudInit
Indicates that this setting is placed in a cloudinit file

```yaml
Type: SwitchParameter
Parameter Sets: CloudInit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsKickstart
Indicates that this setting is placed in a Kickstart file

```yaml
Type: SwitchParameter
Parameter Sets: Kickstart
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductKey
The product key to set

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

