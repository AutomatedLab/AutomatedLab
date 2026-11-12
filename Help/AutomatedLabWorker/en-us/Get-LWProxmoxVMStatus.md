---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWProxmoxVMStatus
schema: 2.0.0
---

# Get-LWProxmoxVMStatus

## SYNOPSIS

Retrieves the status of Proxmox virtual machines

## SYNTAX

```
Get-LWProxmoxVMStatus [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION

Retrieves the current running status (Started, Stopped, or Unknown) of one or more Proxmox virtual machines.

## EXAMPLES

### Example 1

```powershell
Get-LWProxmoxVMStatus -ComputerName DC01
```

Retrieves the status of the DC01 virtual machine

### Example 2

```powershell
Get-LWProxmoxVMStatus -ComputerName DC01,SQL01,WEB01
```

Retrieves the status of multiple virtual machines

## PARAMETERS

### -ComputerName

The name(s) of the virtual machine(s) to retrieve status for

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

### System.Collections.Hashtable

## NOTES

## RELATED LINKS
