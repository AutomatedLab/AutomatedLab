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

```
Get-LabVirtualNetwork [<CommonParameters>]
```

## DESCRIPTION
Returns all existing virtual networks (switches) on a Hyper-V host

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

