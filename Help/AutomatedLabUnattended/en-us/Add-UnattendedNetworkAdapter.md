---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Add-UnattendedNetworkAdapter
schema: 2.0.0
---

# Add-UnattendedNetworkAdapter

## SYNOPSIS
Add a network adapter to the unattend file

## SYNTAX

### Windows (Default)
```
Add-UnattendedNetworkAdapter [-Interfacename <String>] [-IpAddresses <IPNetwork[]>] [-Gateways <IPAddress[]>]
 [-DnsServers <IPAddress[]>] [-ConnectionSpecificDNSSuffix <String>] [-DnsDomain <String>]
 [-UseDomainNameDevolution <String>] [-DNSSuffixSearchOrder <String>]
 [-EnableAdapterDomainNameRegistration <String>] [-DisableDynamicUpdate <String>] [-NetbiosOptions <String>]
 [<CommonParameters>]
```

### CloudInit
```
Add-UnattendedNetworkAdapter [-Interfacename <String>] [-IpAddresses <IPNetwork[]>] [-Gateways <IPAddress[]>]
 [-DnsServers <IPAddress[]>] [-ConnectionSpecificDNSSuffix <String>] [-DnsDomain <String>]
 [-UseDomainNameDevolution <String>] [-DNSSuffixSearchOrder <String>]
 [-EnableAdapterDomainNameRegistration <String>] [-DisableDynamicUpdate <String>] [-NetbiosOptions <String>]
 [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Add-UnattendedNetworkAdapter [-Interfacename <String>] [-IpAddresses <IPNetwork[]>] [-Gateways <IPAddress[]>]
 [-DnsServers <IPAddress[]>] [-ConnectionSpecificDNSSuffix <String>] [-DnsDomain <String>]
 [-UseDomainNameDevolution <String>] [-DNSSuffixSearchOrder <String>]
 [-EnableAdapterDomainNameRegistration <String>] [-DisableDynamicUpdate <String>] [-NetbiosOptions <String>]
 [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Add-UnattendedNetworkAdapter [-Interfacename <String>] [-IpAddresses <IPNetwork[]>] [-Gateways <IPAddress[]>]
 [-DnsServers <IPAddress[]>] [-ConnectionSpecificDNSSuffix <String>] [-DnsDomain <String>]
 [-UseDomainNameDevolution <String>] [-DNSSuffixSearchOrder <String>]
 [-EnableAdapterDomainNameRegistration <String>] [-DisableDynamicUpdate <String>] [-NetbiosOptions <String>]
 [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Add a network adapter to the unattend file.
Default is Windows, switch parameters can be used for either Kickstart or AutoYAST.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-UnattendedNetworkAdapter -InterfaceName lan01 -IpAddresses 192.168.2.12/24 -Gateways 192.168.2.1 -DnsServers 192.168.2.10,192.168.2.11 -DnsDomain contoso.com -IsKickstart
```

Add the network adapter lan01 to the Kickstart file for a VM.
Default is Windows, switch parameters can be used for either Kickstart or AutoYAST.

## PARAMETERS

### -ConnectionSpecificDNSSuffix
DNS suffix for this connection.
Not used on Linux.

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

### -DisableDynamicUpdate
Disable the dynamic update of this adapter.
Not used on Linux.

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

### -DnsDomain
The DNS domain name for this connection

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
The list of DNS servers for this adapter

```yaml
Type: IPAddress[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DNSSuffixSearchOrder
The DNS suffix search order.
Not used on Linux.

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

### -EnableAdapterDomainNameRegistration
Enable the DNS registration of this adapter.
Not used on Linux.

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

### -Gateways
The gateways for this connection

```yaml
Type: IPAddress[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interfacename
The interface name of this connection

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

### -IpAddresses
The IP addresses to assign

```yaml
Type: IPNetwork[]
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

### -NetbiosOptions
The NetBIOS options for this adapter.
0 Default, 1 Enabled, 2 Disabled

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

### -UseDomainNameDevolution
Enable Domain Name Devolution.
Windows only.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

