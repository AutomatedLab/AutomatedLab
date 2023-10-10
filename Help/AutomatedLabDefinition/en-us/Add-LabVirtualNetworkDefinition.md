---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Add-LabVirtualNetworkDefinition
schema: 2.0.0
---

# Add-LabVirtualNetworkDefinition

## SYNOPSIS
Adds a definition of a virtual network

## SYNTAX

```
Add-LabVirtualNetworkDefinition [[-Name] <String>] [[-AddressSpace] <IPNetwork>]
 [[-VirtualizationEngine] <VirtualizationHost>] [[-HyperVProperties] <Hashtable[]>]
 [[-AzureProperties] <Hashtable[]>] [[-ManagementAdapter] <NetworkAdapter>] [[-ResourceName] <String>]
 [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
For Hyper-V, a definition of a virtual switch is created associated with the address space for the virtual switch.
For Azure, a definition of a virtual network is created associated with the address space for the virtual network.

## EXAMPLES

### Example 1
```powershell
Add-LabVirtualNetworkDefinition -Name Network1 -AddressSpace 192.168.10.0/24
```

Adds a definition of a virtual network with the name 'Network1' and with an address space of 192.168.10.0/24 (which is a subnet mask of 255.255.255.0).
Hyper-V machines can then be configured (defined) to use this network using -Network parameter.
Virtual switch type will be internal.

### Example 2
```powershell
Add-LabVirtualNetworkDefinition -Name Network2
```

Adds a definition of a virtual network with the name 'Network2' but without an address space.
When starting deployment, the address space will be determined by automatically scanning for an available address space.
Hyper-V machines can then be configured (defined) to use this network using -Network parameter.
Virtual switch type will be internal.

### Example 3
```powershell
Add-LabVirtualNetworkDefinition -Name Network3 -AddressSpace 192.168.0.0/16 -VirtualizationEngine Azure
```

Adds a definition of a virtual network with the name 'Network3' and with an address space of 192.168.0.0/16 (which is a subnet mask of 255.255.0.0).
Azure machines can then be configured (defined) to use this network using -Network parameter.

### Example 4
```powershell
Add-LabVirtualNetworkDefinition -Name Network4 -AddressSpace 192.168.0.0/16 -VirtualizationEngine Azure -AzureProperties @{SubnetName = 'Subnet1';LocationName = 'West Europe';DnsServers = '192.168.10.4';ConnectToVnets = 'Network8'}
```

Adds a definition of a virtual network with the name 'Network4' and with an address space of 192.168.0.0/16 (which is a subnet mask of 255.255.0.0).
A subnet will be created inside the virtual network called 'Subnet1'.
Virtual network will be placed in Azure data center 'West Europe'.
DNS server for virtual network will be '192.168.10.4' and a VPN gateway will be created and configured to route between the network created ('Network4') and 'Network8'' Azure machines can then be configured (defined) to use this network using -Network parameter.

### Example 5
```powershell
Add-LabVirtualNetworkDefinition -Name Network5 -AddressSpace 192.168.10.0/24 -VirtualizationEngine HyperV -HyperVProperties @{SwitchType = 'External';AdapterName = 'Ethernet adapter vEthernet (External)'}
```

Adds a definition of a virtual network with the name 'Network5' and with an address space of 192.168.10.0/24 (which is a subnet mask of 255.255.255.0).
Type of Hyper-V virtual switch will be external and connected/bridged to the physical adapter with the name 'Ethernet adapter vEthernet (External)'.
Machines can then be configured (defined) to use this network using -Network parameter.

## PARAMETERS

### -AddressSpace
Address space of virtual network defined in the format '192.168.10.0/24'

```yaml
Type: IPNetwork
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureProperties
Extra properties for Azure based virtual network.
Options are:   SubnetName:           Name of subnet to be create inside the virtual network. 
SubnetAddressPrefix:  If a subnet of another size than the virtual network is desired, use this parameter to specify this. 
LocationName:         Azure Datacenter of where to create the virtual network. 
DnsServers:           DNS servers for the virtual network.
All machines in the virtual network will be configured to use these DNS servers if they are not configured manually. 
ConnectToVnets:       If specified, a VPN gateway will be created and configure to connect the network being created with the network(s) specified by this parameter.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HyperVProperties
Extra properties for Hyper-V based virtual network.
Options are; type of virtual switch and name of physical adapter to connect to (if type of virtual switch is 'External')

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ManagementAdapter
Which management adapter to use. Will add an IP address for that adapter.

```yaml
Type: NetworkAdapter
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of virtual network

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: (Get-LabDefinition).Name
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Wheter or not the virtual network will be returned as an object

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceName
Name of the resource in the resource group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualizationEngine
Virtualization engine for network

```yaml
Type: VirtualizationHost
Parameter Sets: (All)
Aliases:
Accepted values: HyperV, Azure, VMWare

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### None
## NOTES

## RELATED LINKS

