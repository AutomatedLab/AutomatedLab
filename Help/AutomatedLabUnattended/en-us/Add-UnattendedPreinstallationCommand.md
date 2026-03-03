---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Add-UnattendedPreinstallationCommand

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Windows (Default)
```
Add-UnattendedPreinstallationCommand -Command <String> -Description <String> [<CommonParameters>]
```

### CloudInit
```
Add-UnattendedPreinstallationCommand -Command <String> -Description <String> [-IsCloudInit]
 [<CommonParameters>]
```

### Yast
```
Add-UnattendedPreinstallationCommand -Command <String> -Description <String> [-IsAutoYast]
 [<CommonParameters>]
```

### Kickstart
```
Add-UnattendedPreinstallationCommand -Command <String> -Description <String> [-IsKickstart]
 [<CommonParameters>]
```

## DESCRIPTION

Add a pre-installation command to an unattended setup file.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-UnattendedPreinstallationCommand -IsCloudInit -Description 'Enable Hardware Experience' -Command "echo 'linux-generic-hwe-22.04' > /run/kernel-meta-package"
```

Adds a Ubuntu-specific command to a cloudinit file

## PARAMETERS

### -Command

The command to run. Usually, try to ensure it does not throw or exit non-zero unless your unattended
system can take it.

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

### -Description

The command description.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
