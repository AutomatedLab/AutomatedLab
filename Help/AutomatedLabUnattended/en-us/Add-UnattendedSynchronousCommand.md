---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Add-UnattendedSynchronousCommand
schema: 2.0.0
---

# Add-UnattendedSynchronousCommand

## SYNOPSIS
Add commands to the post deployment.

## SYNTAX

### Windows (Default)
```
Add-UnattendedSynchronousCommand -Command <String> -Description <String> [<CommonParameters>]
```

### CloudInit
```
Add-UnattendedSynchronousCommand -Command <String> -Description <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Add-UnattendedSynchronousCommand -Command <String> -Description <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Add-UnattendedSynchronousCommand -Command <String> -Description <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Add commands to the post deployment.
Apply common sense when adding Linux commands, these work differently.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-UnattendedSynchronousCommand -Command 'useradd mary -G mary -g wheel' -IsKickstart
```

Adds a command to add a user with a specific group membership set to a Kickstart file.

## PARAMETERS

### -Command
The command to execute

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
The description of the command.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

