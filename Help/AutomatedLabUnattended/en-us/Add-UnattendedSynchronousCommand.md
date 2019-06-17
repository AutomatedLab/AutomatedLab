---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Add-UnattendedSynchronousCommand

## SYNOPSIS
Add commands to the post deployment. 

## SYNTAX

```
Add-UnattendedSynchronousCommand [-Command] <String> [-Description] <String> [-IsKickstart] [-IsAutoYast]
 [<CommonParameters>]
```

## DESCRIPTION
Add commands to the post deployment. Apply common sense when adding Linux commands, these work differently.

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
Position: 0
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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsAutoYast
Indicates that this setting is placed in an AutoYAST file

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

### -IsKickstart
Indicates that this setting is placed in a Kickstart file

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
