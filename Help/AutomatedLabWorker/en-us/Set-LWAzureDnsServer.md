---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Set-LWAzureDnsServer

## SYNOPSIS
Set the DNS servers of an Azure virtual network

## SYNTAX

```
Set-LWAzureDnsServer [-VirtualNetwork] <VirtualNetwork[]> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Set the DNS servers of an Azure virtual network to the lab DNS servers, if configured

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LWAzureDnsServer -VirtualNetwork (Get-Lab).VirtualNetworks
```

Configure the proper DNS servers for all Azure VNets of a lab

## PARAMETERS

### -PassThru
Return the Azure VNets

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualNetwork
The networks to configure

```yaml
Type: VirtualNetwork[]
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
