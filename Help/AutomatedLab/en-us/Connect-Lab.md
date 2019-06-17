---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Connect-Lab

## SYNOPSIS
Connect two labs via VPN

## SYNTAX

### Lab2Lab (Default)
```
Connect-Lab [-SourceLab] <String> [-DestinationLab] <String> [-NetworkAdapterName <String>]
 [<CommonParameters>]
```

### Site2Site
```
Connect-Lab [-SourceLab] <String> [-DestinationIpAddress] <String> [-PreSharedKey] <String>
 [[-AddressSpace] <String[]>] [-NetworkAdapterName <String>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet allows you to connect two labs through a persistent IPSEC VPN connection.
Currently connections from Hyper-V labs to Azure labs, connections from Hyper-V labs to any VPN Gateway and connections of two Azure labs are possible.

To make use of this cmdlet, your on-premises lab needs to contain a router, i.e.
a machine with the Routing role and one external NIC.

## EXAMPLES

### On-Prem to Azure


```powershell
Connect-Lab -SourceLab MyOnPremisesLab -DestinationLab MyAzureLab
```

This connects the two existing labs, MyOnPremisesLab - a Hyper-V lab with at least one router - and MyAzureLab, which is any Azure based lab.

On Azure, the resources Virtual Network Gateway, Local Network Gateway, Public IP Address and Virtual Network Connection will be created.
On Hyper-V, S2SVPN will be enabled on the router.

### On-Prem to somewhere


```powershell
Connect-Lab -SourceLab MyOnPremLab -DestinationIpAddress myvpngateway.mycompany.com -PreSharedKey VeryS3cureKey -AddressSpace @("192.168.30.0/24", "192.168.60.0/24", "192.168.90.0/24")
```

This command connects the Hyper-V lab MyOnPremLab to a VPN gateway listening on myvpngateway.mycompany.com.
Requests to one of the address spaces "192.168.30.0/24", "192.168.60.0/24" and "192.168.90.0/24" will be routed through the VPN connection

## PARAMETERS

### -SourceLab
The source lab name

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

### -DestinationLab
The destination lab name

```yaml
Type: String
Parameter Sets: Lab2Lab
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkAdapterName
Optionally specify the adapter to use

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

### -AddressSpace
One or more address spaces to be routed in case you are connecting to an external VPN gateway and not to another lab.
Example: 192.168.2.30/24

```yaml
Type: String[]
Parameter Sets: Site2Site
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationIpAddress
S2S VPN: The IP address of the remote VPN gateway

```yaml
Type: String
Parameter Sets: Site2Site
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreSharedKey
The pre-shared key for the S2S VPN

```yaml
Type: String
Parameter Sets: Site2Site
Aliases:

Required: True
Position: 2
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
