---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Add-LWAzureLoadBalancedPort

## SYNOPSIS
Add a new port to the Azure load balancer

## SYNTAX

```
Add-LWAzureLoadBalancedPort [-Port] <UInt16> [-DestinationPort] <UInt16> [-ComputerName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Add a new port to the Azure load balancer for the current lab. Please refer to the official
documentation to learn more about the limitations of the inbound NAT rules of a load balancer.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LWAzureLoadBalancedPort -Port 4711 -DestinationPort 22 -ComputerName CentOS01
```

Adds port 4711 to the Azure load balancer and points it to port 22 on machine CentOS01

## PARAMETERS

### -ComputerName
The machine to add a load balanced port for.

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

### -DestinationPort
The destination port

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
The port on the load balancer. Cannot be in use already.

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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
