---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabVirtualNetwork
schema: 2.0.0
---

# Get-LabVirtualNetwork

## SYNOPSIS
Returns all existing virtual networks (switches) on a Hyper-V host

## SYNTAX

### ByName
```
Get-LabVirtualNetwork [-Name <String>] [<CommonParameters>]
```

### All
```
Get-LabVirtualNetwork [-All] [<CommonParameters>]
```

## DESCRIPTION
Returns all existing virtual networks (switches) within the imported lab. If the `-All` switch is used, all virtual networks (switches) on the Hyper-V host are returned.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVirtualNetwork | Format-Table Name, AddressSpace
```

Get the network name and address space of all lab networks, e.g.
Name           AddressSpace
----           ------------
DscWorkshop    192.168.111.0/24
Default Switch 172.18.29.64/28

## PARAMETERS

### -Name
The name of the virtual network.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Indicates that all switches on the Hyper-V host should be returned.

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
