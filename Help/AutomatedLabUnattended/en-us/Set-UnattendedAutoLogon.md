---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedAutoLogon
schema: 2.0.0
---

# Set-UnattendedAutoLogon

## SYNOPSIS
Set the auto logon account in the unattend file

## SYNTAX

### Windows (Default)
```
Set-UnattendedAutoLogon -DomainName <String> -Username <String> -Password <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedAutoLogon -DomainName <String> -Username <String> -Password <String> [-IsCloudInit]
 [<CommonParameters>]
```

### Yast
```
Set-UnattendedAutoLogon -DomainName <String> -Username <String> -Password <String> [-IsAutoYast]
 [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedAutoLogon -DomainName <String> -Username <String> -Password <String> [-IsKickstart]
 [<CommonParameters>]
```

## DESCRIPTION
Set the auto logon account in the unattend file

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedAutoLogon -Domain contoso.com -User Hans -Password Somepass1
```

Enables the automatic login of the account Hans in the domain contoso.com

## PARAMETERS

### -DomainName
The domain name

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

### -Password
The password of the autologon account

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

### -Username
The account name to automatically log on

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

