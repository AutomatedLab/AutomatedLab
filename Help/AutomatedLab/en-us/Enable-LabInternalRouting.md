---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Enable-LabInternalRouting
schema: 2.0.0
---

# Enable-LabInternalRouting

## SYNOPSIS
Configure RRAS to route between lab VNets

## SYNTAX

```
Enable-LabInternalRouting [-RoutingNetworkName] <String> [<CommonParameters>]
```

## DESCRIPTION
Configure RRAS to route between lab VNets

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabInternalRouting -RoutingNetworkName Routing
```

Configures RRAS to route between VNets using the VNet Routing

## PARAMETERS

### -RoutingNetworkName
Name of routing network

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

