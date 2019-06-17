---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Set-UnattendedDomain

## SYNOPSIS
Set the domain membership

## SYNTAX

```
Set-UnattendedDomain [-DomainName] <String> [-Username] <String> [-Password] <String> [-IsKickstart]
 [-IsAutoYast] [<CommonParameters>]
```

## DESCRIPTION
Set the domain membership. On Linux, requires the necessary packages for the realm
command to complete. These are oddjob, oddjob-mkhomedir, sssd, adcli and krb5-workstation.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedDomain -DomainName contoso.com -UserName Install -Password Somepass1
```

Configures the domain join credentials for a Windows unattend file.

## PARAMETERS

### -DomainName
The domain to configure

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

### -Password
The password of the domain join account

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
The domain join account

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
