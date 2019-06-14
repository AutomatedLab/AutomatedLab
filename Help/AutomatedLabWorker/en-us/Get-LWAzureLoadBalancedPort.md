---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureLoadBalancedPort

## SYNOPSIS
List ports on the Azure load balancer

## SYNTAX

```
Get-LWAzureLoadBalancedPort [[-Port] <UInt16>] [[-DestinationPort] <UInt16>] [-ComputerName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
List the current ports on the lab's load balancer for a machine. Capable of filtering port and
destination port

## EXAMPLES

### Example 1
```powershell
if (-not (Get-LWAzureLoadBalancedPort -DestinationPort 8080 -ComputerName Web01))
{
    Add-LWAzureLoadBalancedPort -Port 4711 -DestinationPort 8080 -ComputerName Web01
}
```

If not already load-balanced, create a new port to be natted to Web01

## PARAMETERS

### -ComputerName
The machine to filter on

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
The machine's destination port to filter on

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
The frontend port to filter on

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: False
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
