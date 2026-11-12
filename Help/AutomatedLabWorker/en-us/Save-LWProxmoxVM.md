---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Save-LWProxmoxVM
schema: 2.0.0
---

# Save-LWProxmoxVM

## SYNOPSIS

Saves the state of Proxmox virtual machines

## SYNTAX

```
Save-LWProxmoxVM [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Suspends and saves the state of one or more Proxmox virtual machines to disk. The VMs can later be resumed from this saved state.

## EXAMPLES

### Example 1

```powershell
Save-LWProxmoxVM -ComputerName DC01
```

Saves the state of the DC01 virtual machine

### Example 2

```powershell
Save-LWProxmoxVM -ComputerName DC01,SQL01,WEB01
```

Saves the state of multiple virtual machines

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to save

```yaml
Type: String[]
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
