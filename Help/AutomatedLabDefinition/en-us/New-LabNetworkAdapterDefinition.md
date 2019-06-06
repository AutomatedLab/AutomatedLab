---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# New-LabNetworkAdapterDefinition

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### manual (Default)
```
New-LabNetworkAdapterDefinition -VirtualSwitch <String> [-InterfaceName <String>] [-Ipv4Address <IPNetwork[]>]
 [-Ipv4Gateway <IPAddress>] [-Ipv4DNSServers <IPAddress[]>] [-IPv6Address <IPNetwork[]>]
 [-IPv6AddressPrefix <Int32>] [-IPv6Gateway <String>] [-IPv6DNSServers <String[]>]
 [-ConnectionSpecificDNSSuffix <String>] [-AppendParentSuffixes <Boolean>] [-AppendDNSSuffixes <String[]>]
 [-RegisterInDNS <Boolean>] [-DnsSuffixInDnsRegistration <Boolean>] [-NetBIOSOptions <String>]
 [-AccessVLANID <Int32>] [-ManagementAdapter <Boolean>] [<CommonParameters>]
```

### dhcp
```
New-LabNetworkAdapterDefinition -VirtualSwitch <String> [-InterfaceName <String>] [-UseDhcp]
 [-Ipv4DNSServers <IPAddress[]>] [-IPv6DNSServers <String[]>] [-ConnectionSpecificDNSSuffix <String>]
 [-AppendParentSuffixes <Boolean>] [-AppendDNSSuffixes <String[]>] [-RegisterInDNS <Boolean>]
 [-DnsSuffixInDnsRegistration <Boolean>] [-NetBIOSOptions <String>] [-AccessVLANID <Int32>]
 [-ManagementAdapter <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AccessVLANID
{{ Fill AccessVLANID Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AppendDNSSuffixes
{{ Fill AppendDNSSuffixes Description }}

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

### -AppendParentSuffixes
{{ Fill AppendParentSuffixes Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConnectionSpecificDNSSuffix
{{ Fill ConnectionSpecificDNSSuffix Description }}

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

### -DnsSuffixInDnsRegistration
{{ Fill DnsSuffixInDnsRegistration Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPv6Address
{{ Fill IPv6Address Description }}

```yaml
Type: IPNetwork[]
Parameter Sets: manual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPv6AddressPrefix
{{ Fill IPv6AddressPrefix Description }}

```yaml
Type: Int32
Parameter Sets: manual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPv6DNSServers
{{ Fill IPv6DNSServers Description }}

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

### -IPv6Gateway
{{ Fill IPv6Gateway Description }}

```yaml
Type: String
Parameter Sets: manual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InterfaceName
{{ Fill InterfaceName Description }}

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

### -Ipv4Address
{{ Fill Ipv4Address Description }}

```yaml
Type: IPNetwork[]
Parameter Sets: manual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ipv4DNSServers
{{ Fill Ipv4DNSServers Description }}

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

### -Ipv4Gateway
{{ Fill Ipv4Gateway Description }}

```yaml
Type: IPAddress
Parameter Sets: manual
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ManagementAdapter
{{ Fill ManagementAdapter Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetBIOSOptions
{{ Fill NetBIOSOptions Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Default, Enabled, Disabled

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RegisterInDNS
{{ Fill RegisterInDNS Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseDhcp
{{ Fill UseDhcp Description }}

```yaml
Type: SwitchParameter
Parameter Sets: dhcp
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualSwitch
{{ Fill VirtualSwitch Description }}

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
