---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Repair-LWProxmoxNetworkConfig
schema: 2.0.0
---

# Repair-LWProxmoxNetworkConfig

## SYNOPSIS

Repairs network adapter configuration on Proxmox virtual machines.

## SYNTAX

```
Repair-LWProxmoxNetworkConfig [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Recovers missing MAC addresses from the Proxmox VM configuration and renames network adapters inside the guest OS to match the lab definition. This is typically called after a VM is started to ensure adapters are named consistently.

## EXAMPLES

### Example 1

```powershell
Repair-LWProxmoxNetworkConfig -ComputerName DC01
```

Repairs the network adapter configuration for the DC01 virtual machine.

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) whose network configuration should be repaired.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
