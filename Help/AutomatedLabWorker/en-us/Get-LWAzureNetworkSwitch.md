---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureNetworkSwitch

## SYNOPSIS
Get the Azure Virtual Network associated with a lab network

## SYNTAX

```
Get-LWAzureNetworkSwitch [-virtualNetwork] <VirtualNetwork[]> [<CommonParameters>]
```

## DESCRIPTION
Get the Azure Virtual Network associated with a lab network

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureNetworkSwitch -VirtualNetwork (Get-LabVirtualNetworkDefinition -Name LabNet)
```

During lab deployment, return the virtual network that has been provisioned
from the network definition LabNet

## PARAMETERS

### -virtualNetwork
The lab network to search for

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
