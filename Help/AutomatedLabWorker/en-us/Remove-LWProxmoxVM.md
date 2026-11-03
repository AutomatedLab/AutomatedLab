---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWProxmoxVM
schema: 2.0.0
---

# Remove-LWProxmoxVM

## SYNOPSIS

Removes a Proxmox virtual machine

## SYNTAX

```
Remove-LWProxmoxVM [-Name] <String> [[-VmId] <Int32>] [<CommonParameters>]
```

## DESCRIPTION

Removes a Proxmox virtual machine. Every decision rests on a fresh lookup on all available Proxmox nodes, never on the session cache, which can still list a VM that was deleted or migrated long ago.

When the lab recorded the VMID of the machine, pass it with -VmId: only the VM with that VMID is removed, and other VMs with the same name are reported and left alone. Without a VMID, the function refuses to choose when several VMs have the name.

A running VM is stopped first. The exit status of the stop task and of the destroy task is checked, and another fresh lookup proves that the VM is gone. A failure ends with a terminating error that names the node, the VMID and the Proxmox status text. A task that ends with warnings is accepted only when the VM is stopped or gone afterwards.

A VM that no available node lists counts as removed already: the function writes a warning and returns the outcome NotFound. When a node does not answer, absence cannot be proven and the function fails instead.

The function does not purge the VM from backup, replication or HA configurations and does not destroy disks that the VM configuration does not reference.

## EXAMPLES

### Example 1

```powershell
Remove-LWProxmoxVM -Name DC01
```

Removes the Proxmox VM named DC01. Fails if several VMs have this name.

### Example 2

```powershell
Remove-LWProxmoxVM -Name DC01 -VmId 105
```

Removes the Proxmox VM named DC01 that has the VMID 105 and leaves other VMs named DC01 alone.

### Example 3

```powershell
Get-LabVM -ComputerName TEST01 | ForEach-Object { Remove-LWProxmoxVM -Name $_.ResourceName }
```

Removes a lab VM from Proxmox

## PARAMETERS

### -Name

The name of the virtual machine to remove

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmId

The VMID that AutomatedLab recorded when it created the VM, stored as VmId in the ProxmoxProperties of the lab machine. Only the VM with this VMID is removed. Omit the parameter or pass 0 when the VMID is unknown.

```yaml
Type: Int32
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

### System.Management.Automation.PSObject

An object with the properties Name, VmId, Node and Outcome. Outcome is Removed when the VM was removed and NotFound when no available node lists it.

## NOTES

## RELATED LINKS
