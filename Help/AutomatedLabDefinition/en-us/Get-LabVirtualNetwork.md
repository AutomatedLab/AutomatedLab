---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabVirtualNetwork

## SYNOPSIS
Returns all existing virtual networks (switches) on a Hyper-V host

## SYNTAX

```
Get-LabVirtualNetwork
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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
