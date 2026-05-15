---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Get-LWProxmoxNode
schema: 2.0.0
---

# Get-LWProxmoxNode

## SYNOPSIS

Retrieves Proxmox cluster nodes

## SYNTAX

```
Get-LWProxmoxNode [[-Name] <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Retrieves information about Proxmox cluster nodes. Can filter by node name or return all nodes.

## EXAMPLES

### Example 1

```powershell
Get-LWProxmoxNode
```

Gets all Proxmox nodes in the cluster

### Example 2

```powershell
Get-LWProxmoxNode -Name 'pve1', 'pve2'
```

Gets specific Proxmox nodes by name

### Example 3

```powershell
$nodes = Get-LWProxmoxNode
$nodes | Select-Object node, status, uptime
```

Retrieves all nodes and displays selected properties

## PARAMETERS

### -Name

The name(s) of the Proxmox node(s) to retrieve. If not specified, all nodes are returned.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

Returns Proxmox node objects with properties including node name, status, uptime, and other node information.

## NOTES

Requires an active connection to a Proxmox cluster. Use Connect-LabProxmoxCluster to establish a connection.

## RELATED LINKS

[Connect-LabProxmoxCluster](Connect-LabProxmoxCluster.md)

[Test-LabProxmoxConnection](Test-LabProxmoxConnection.md)
