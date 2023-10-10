---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/New-LabNetworkAdapterDefinition
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
 [-AccessVLANID <Int32>] [-ManagementAdapter <Boolean>] [-MacAddress <String>] [-Default <Boolean>]
 [<CommonParameters>]
```

### dhcp
```
New-LabNetworkAdapterDefinition -VirtualSwitch <String> [-InterfaceName <String>] [-UseDhcp]
 [-Ipv4DNSServers <IPAddress[]>] [-IPv6DNSServers <String[]>] [-ConnectionSpecificDNSSuffix <String>]
 [-AppendParentSuffixes <Boolean>] [-AppendDNSSuffixes <String[]>] [-RegisterInDNS <Boolean>]
 [-DnsSuffixInDnsRegistration <Boolean>] [-NetBIOSOptions <String>] [-AccessVLANID <Int32>]
 [-ManagementAdapter <Boolean>] [-MacAddress <String>] [-Default <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Creates a network adapter definition roughly interpreted as a NIC.
This NIC can then be connected to a lab machine when defining the machine using Add-LabMachineDefinition

## EXAMPLES

### Example 1
```powershell
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.30.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name POSHFS1 -Memory 512MB -Roles FileServer, Routing -NetworkAdapter $netAdapter
```

In order to create a machine capable of routing, you can assign two network adapter definitions to it

## PARAMETERS

### -AccessVLANID
The VLAN ID to configure

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
List of DNS suffixes to append

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
Indicates that parent suffixes should be appended to the DNS suffix

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
The DNS suffix (Windows)

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

### -Default
Indicates that this adapter will be the default adapter

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
Indicates that the DNS suffix should be included in the DNS registration

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

### -InterfaceName
The name of the interface on the VM

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
The IP address of the adapter

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
The DNS servers to use

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
The gateway that should be used

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

### -IPv6Address
The IPv6 address of this adapter

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
The IPv6 prefix

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
The IPv6 DNS server list

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
The IPv6 gateway to configure

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

### -MacAddress
The hardware address of the virtual adapter

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

### -ManagementAdapter
Indicates that this adapter is used as a management adapter

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
The NetBIOS options to set (Default, Enabled, Disabled)

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
Indicates that the name should be registered in DNS

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
Indicates that DHCP should be used.
Useful e.g.
for the Default Switch

```yaml
Type: SwitchParameter
Parameter Sets: dhcp
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualSwitch
The name of the virtual switch.

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

## OUTPUTS

## NOTES

## RELATED LINKS

