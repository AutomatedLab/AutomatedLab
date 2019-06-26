---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabVirtualNetworkDefinition

## SYNOPSIS
Returns all virtual network definitions in the lab

## SYNTAX

### ByName
```
Get-LabVirtualNetworkDefinition [-Name <String>] [<CommonParameters>]
```

### ByAddressSpace
```
Get-LabVirtualNetworkDefinition -AddressSpace <String> [<CommonParameters>]
```

## DESCRIPTION
Returns all virtual network definitions in the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVirtualNetworkDefinition -AddressSpace 192.168.2.0/24
```

Tries to locate the network definition that has the address space 192.168.2.0/24

## PARAMETERS

### -Name
The name of the network

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

### -AddressSpace
The address space of the network in CIDR notation

```yaml
Type: String
Parameter Sets: ByAddressSpace
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
