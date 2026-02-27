---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Dismount-LWProxmoxIsoImage
schema: 2.0.0
---

# Dismount-LWProxmoxIsoImage

## SYNOPSIS

Unmounts all mounted ISO images from a Proxmox VM.

## SYNTAX

### ByApiParams (Default)

```
Dismount-LWProxmoxIsoImage -Node <String> -VmId <Int32> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByComputerName

```
Dismount-LWProxmoxIsoImage [-ComputerName] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Scans the VM configuration for all SCSI slots that have an ISO image
mounted (media=cdrom with an actual ISO, not 'none'). Each discovered
slot is changed to an empty CD-ROM drive. The SCSI device remains but
the disc is ejected.

Can be invoked with either a ComputerName (lab machine name) or with direct
Proxmox API parameters (Node, VmId). When ComputerName is used, the CD-ROM
drives are fully removed via Remove-LWProxmoxCdDrive.

Requires an active connection to the Proxmox cluster.

## EXAMPLES

### Example 1

```powershell
Dismount-LWProxmoxIsoImage -ComputerName 'Server01'
```

Finds and removes all CD-ROM drives from the lab VM 'Server01'.

### Example 2

```powershell
Dismount-LWProxmoxIsoImage -Node 'rz1pinhst101' -VmId 9004
```

Finds and ejects all mounted ISO images from VM 9004.

## PARAMETERS

### -ComputerName

The name of the lab machine. The machine's Proxmox properties are used to
resolve the target node and VM ID automatically.

```yaml
Type: String[]
Parameter Sets: ByComputerName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Node

The name of the Proxmox node where the VM is running.

```yaml
Type: String
Parameter Sets: ByApiParams
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
Parameter Sets: ByApiParams
Aliases:

Required: True
Position: Named
Default value: None
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
