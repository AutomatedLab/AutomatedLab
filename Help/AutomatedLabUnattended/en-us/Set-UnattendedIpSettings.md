---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedIpSettings
schema: 2.0.0
---

# Set-UnattendedIpSettings

## SYNOPSIS
Set the default network configuration

## SYNTAX

### Windows (Default)
```
Set-UnattendedIpSettings [-IpAddress <String>] [-Gateway <String>] [-DnsServers <String[]>]
 [-DnsDomain <String>] [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedIpSettings [-IpAddress <String>] [-Gateway <String>] [-DnsServers <String[]>]
 [-DnsDomain <String>] [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedIpSettings [-IpAddress <String>] [-Gateway <String>] [-DnsServers <String[]>]
 [-DnsDomain <String>] [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedIpSettings [-IpAddress <String>] [-Gateway <String>] [-DnsServers <String[]>]
 [-DnsDomain <String>] [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the default network configuration

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedIpSettings -IpAddress 192.168.2.12 -Gateway 192.168.2.1 -DnsServer 8.8.8.8,8.8.4.4
```

Configures the IP settings

## PARAMETERS

### -DnsDomain
The DNS domain to configure

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServers
The DNS servers to add

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Gateway
The gateway to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
The IP address to configure

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

