---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedAdministratorPassword
schema: 2.0.0
---

# Set-UnattendedAdministratorPassword

## SYNOPSIS
Set the admin user's password

## SYNTAX

### Windows (Default)
```
Set-UnattendedAdministratorPassword -Password <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedAdministratorPassword -Password <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedAdministratorPassword -Password <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedAdministratorPassword -Password <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the admin user's password.
Sets both the root as well as the user password.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedAdministratorPassword -Password swordfish -IsKickstart
```

For the Kickstart file, sets the password to swordfish

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

### -Password
The password to set

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

