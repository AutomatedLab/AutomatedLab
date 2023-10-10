---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedUserLocale
schema: 2.0.0
---

# Set-UnattendedUserLocale

## SYNOPSIS
The locale to configure

## SYNTAX

### Windows (Default)
```
Set-UnattendedUserLocale -UserLocale <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedUserLocale -UserLocale <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedUserLocale -UserLocale <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedUserLocale -UserLocale <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
The locale to configure

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedUserLocale -UserLocale ja-jp
```

Configures the user locale to Japanese.

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

### -UserLocale
The locale to use.
Refer to \[cultureinfo\]::GetCultures('AllCultures')

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

