---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWAzureNetworkSwitch

## SYNOPSIS
Creates a new Azure virtual network

## SYNTAX

```
New-LWAzureNetworkSwitch [-VirtualNetwork] <VirtualNetwork[]> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Creates a new Azure virtual network that maps to the lab network definition

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWAzureNetworkSwitch -VirtualNetwork (Get-LabVirtualNetworkDefinition)
```

Creates all virtual networks in the lab

## PARAMETERS

### -PassThru
Indicates that the VNets should be returned

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
The virtual networks to create

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
