---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedAdministratorName
schema: 2.0.0
---

# Set-UnattendedAdministratorName

## SYNOPSIS
Set the admin name

## SYNTAX

### Windows (Default)
```
Set-UnattendedAdministratorName -Name <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedAdministratorName -Name <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedAdministratorName -Name <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedAdministratorName -Name <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the admin name.
On a Linux system, adds another root user.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedAdministratorName -Name FranzJosef
```

Sets the local administrator in the Windows unattended file to FranzJosef

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

### -Name
The user name to set.

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

