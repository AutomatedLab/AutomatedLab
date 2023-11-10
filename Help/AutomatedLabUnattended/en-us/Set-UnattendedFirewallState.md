---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedFirewallState
schema: 2.0.0
---

# Set-UnattendedFirewallState

## SYNOPSIS
Enable or disable the OS firewall

## SYNTAX

### Windows (Default)
```
Set-UnattendedFirewallState -State <Boolean> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedFirewallState -State <Boolean> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedFirewallState -State <Boolean> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedFirewallState -State <Boolean> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Enable or disable the OS firewall

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedFirewallState -State $false
```

Disable the OS firewall

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

### -State
Is the firewall enabled or not

```yaml
Type: Boolean
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

