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
Remove-LWProxmoxVM [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION

Removes a Proxmox virtual machine. The VM will be stopped if it is running before removal.

## EXAMPLES

### Example 1

```powershell
Remove-LWProxmoxVM -Name DC01
```

Removes the Proxmox VM named DC01

### Example 2

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
