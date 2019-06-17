---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Remove-LWAzureNetworkSwitch

## SYNOPSIS
Remove an Azure network switch

## SYNTAX

```
Remove-LWAzureNetworkSwitch [-VirtualNetwork] <VirtualNetwork[]> [<CommonParameters>]
```

## DESCRIPTION
Remove an Azure network switch.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWAzureNetworkSwitch -VirtualNetwork (Get-LabVirtualNetworkDefinition)
```

Remove all lab virtual networks on Azure

## PARAMETERS

### -VirtualNetwork
The network to remove

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
