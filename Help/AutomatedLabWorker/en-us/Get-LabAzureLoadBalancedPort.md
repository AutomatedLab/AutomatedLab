---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LabAzureLoadBalancedPort

## SYNOPSIS
Return the custom load-balanced ports of an Azure VM

## SYNTAX

```
Get-LabAzureLoadBalancedPort [[-Port] <UInt16>] [[-DestinationPort] <UInt16>] [-ComputerName] <String>
 [<CommonParameters>]
```

## DESCRIPTION
Return the custom load-balanced ports of an Azure VM. Enables filtering on
load-balanced port and destination port.
Uses the InternalNotes property of a machine.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureLoadBalancedPort -DestinationPort 8080 -ComputerName DscTfs01
```

If exists, return an object containing the load-balanced port and destination port.

## PARAMETERS

### -ComputerName
The machine to list ports from

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
The destination port on the VM

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
The publishes port on the load balancer

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
