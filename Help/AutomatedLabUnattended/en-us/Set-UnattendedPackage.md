---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedPackage
schema: 2.0.0
---

# Set-UnattendedPackage

## SYNOPSIS
Adds additional packages on Linux.

## SYNTAX

### Windows (Default)
```
Set-UnattendedPackage -Package <String[]> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedPackage -Package <String[]> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedPackage -Package <String[]> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedPackage -Package <String[]> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Adds additional packages on Linux.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedPackage -Package '@core','@^graphical-server-environment'
```

Add the package group 'core' and the environment 'graphical-server-environment' to the list of packages to install.

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

### -Package
The packages to install

```yaml
Type: String[]
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

