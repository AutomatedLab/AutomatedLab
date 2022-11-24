---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWVMWareNetworkSwitch
schema: 2.0.0
---

# Get-LWVMWareNetworkSwitch

## SYNOPSIS
Return a VMWare network switch for a lab network

## SYNTAX

```
Get-LWVMWareNetworkSwitch [-VirtualNetwork] <VirtualNetwork[]> [<CommonParameters>]
```

## DESCRIPTION
Return a VMWare network switch for a lab network

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWVMWareNetworkSwitch -VirtualNetwork (Get-LabVirtualNetworkDefinition -Name SkyNet)
```

Return the VSwitch for the SkyNet network

## PARAMETERS

### -VirtualNetwork
The lab network

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

