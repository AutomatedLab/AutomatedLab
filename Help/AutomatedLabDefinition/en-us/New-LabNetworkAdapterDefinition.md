---
external help file: AutomatedLabDefinition.Help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# New-LabNetworkAdapterDefinition

## SYNOPSIS
Creates a network adapter definition roughly interpreted as a NIC

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
Creates a network adapter definition roughly interpreted as a NIC.
This NIC can then be connected to a lab machine when defining the machine using Add-LabMachineDefinition

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -VirtualSwitch
@{Text=}

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

### -InterfaceName
@{Text=}

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
@{Text=}

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

### -Ipv4Gateway
@{Text=}

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

### -Ipv4DNSServers
@{Text=}

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

### -IPv6Address
@{Text=}

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
@{Text=}

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

### -IPv6Gateway
@{Text=}

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

### -IPv6DNSServers
@{Text=}

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

### -ConnectionSpecificDNSSuffix
@{Text=}

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

### -AppendParentSuffixes
@{Text=}

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

### -AppendDNSSuffixes
@{Text=}

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

### -RegisterInDNS
@{Text=}

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

### -DnsSuffixInDnsRegistration
@{Text=}

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
@{Text=}

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

### -UseDhcp
@{Text=}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
