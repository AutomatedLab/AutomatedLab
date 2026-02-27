---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWProxmoxCdDrive
schema: 2.0.0
---

# Remove-LWProxmoxCdDrive

## SYNOPSIS

Removes a SCSI CD-ROM drive from a Proxmox VM.

## SYNTAX

### BySlot (Default)

```
Remove-LWProxmoxCdDrive -Node <String> -VmId <Int32> -ScsiSlot <Int32> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### All

```
Remove-LWProxmoxCdDrive -Node <String> -VmId <Int32> -All [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Completely removes the specified SCSI CD-ROM device from the VM configuration.
Unlike Dismount-LWProxmoxIsoImage (which ejects the disc but keeps the drive),
this function deletes the SCSI device entry entirely.

Can also remove all SCSI CD-ROM drives at once with the -All switch.

Requires an active connection to the Proxmox cluster.

## EXAMPLES

### Example 1

```powershell
Remove-LWProxmoxCdDrive -Node 'rz1pinhst101' -VmId 9004 -ScsiSlot 30
```

Removes the scsi30 device from VM 9004.

### Example 2

```powershell
Remove-LWProxmoxCdDrive -Node 'rz1pinhst101' -VmId 9004 -All
```

Removes all SCSI CD-ROM drives from VM 9004.

## PARAMETERS

### -Node

The name of the Proxmox node where the VM is running.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmId

The numeric ID of the virtual machine.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScsiSlot

The SCSI slot number (0-30) to remove.

```yaml
Type: Int32
Parameter Sets: BySlot
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All

When specified, removes all SCSI CD-ROM drives (scsi0-scsi30) from the VM.

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

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
