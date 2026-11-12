---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWProxmoxVM
schema: 2.0.0
---

# Get-LWProxmoxVM

## SYNOPSIS

Retrieves Proxmox virtual machines

## SYNTAX

```
Get-LWProxmoxVM [[-ComputerName] <String[]>] [[-Node] <Object[]>] [-NoError] [-IncludeTemplates] [-NoCache] [-NoStatusCurrent] [<CommonParameters>]
```

## DESCRIPTION

Retrieves one or more Proxmox virtual machines from the Proxmox cluster. Can filter by computer name and node, and optionally include templates.

## EXAMPLES

### Example 1

```powershell
Get-LWProxmoxVM
```

Retrieves all virtual machines from all Proxmox nodes

### Example 2

```powershell
Get-LWProxmoxVM -ComputerName DC01,SQL01
```

Retrieves specific virtual machines by name

### Example 3

```powershell
Get-LWProxmoxVM -Node pve01 -IncludeTemplates
```

Retrieves all VMs including templates from a specific node

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to retrieve

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Node

The Proxmox node(s) to query. If not specified, all nodes are queried.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoError

Suppress error messages if virtual machines are not found

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTemplates

Include VM templates in the results

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoCache

Force retrieval of fresh VM data instead of using cached information

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoStatusCurrent

Skip retrieving the current status of VMs (faster but less information)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
