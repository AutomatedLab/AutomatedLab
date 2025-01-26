---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Add-UnattendedSshPublicKey
schema: 2.0.0
---

# Add-UnattendedSshPublicKey

## SYNOPSIS

Add SSH public keys to authorized keys file

## SYNTAX

### Windows (Default)
```
Add-UnattendedSshPublicKey -PublicKey <String> [<CommonParameters>]
```

### CloudInit
```
Add-UnattendedSshPublicKey -PublicKey <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Add-UnattendedSshPublicKey -PublicKey <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Add-UnattendedSshPublicKey -PublicKey <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION

Add SSH public keys to authorized keys file

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-UnattendedSshPublicKey -PublicKey (Get-Content -Raw $home/.ssh/PubKey.pub) -CloudInit
```

Adds SSH public key to CloudInit config file

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

### -PublicKey

The SSH public key to add, one single string

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
