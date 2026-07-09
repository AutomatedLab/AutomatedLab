---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/New-LWProxmoxVM
schema: 2.0.0
---

# New-LWProxmoxVM

## SYNOPSIS

Creates a new Proxmox virtual machine

## SYNTAX

```
New-LWProxmoxVM [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION

Creates a new Proxmox virtual machine by cloning a template and configuring it according to the machine definition. Handles network adapters, disks, unattended installation, and initial configuration.

## EXAMPLES

### Example 1

```powershell
$machine = Get-LabVM -ComputerName DC01
New-LWProxmoxVM -Machine $machine
```

Creates a new Proxmox VM based on the machine definition

### Example 2

```powershell
Get-LabVM | Where-Object HostType -eq 'Proxmox' | ForEach-Object { New-LWProxmoxVM -Machine $_ }
```

Creates multiple Proxmox VMs from lab definitions

## PARAMETERS

### -Machine

The machine object containing the VM configuration and settings

```yaml
Type: Machine
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

### System.Boolean

## NOTES

## RELATED LINKS
