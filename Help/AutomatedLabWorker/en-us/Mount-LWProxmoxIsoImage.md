---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Mount-LWProxmoxIsoImage
schema: 2.0.0
---

# Mount-LWProxmoxIsoImage

## SYNOPSIS

Mounts an ISO image to a Proxmox VM as a SCSI CD-ROM drive.

## SYNTAX

### ByApiParams (Default)

```
Mount-LWProxmoxIsoImage -Node <String> -VmId <Int32> -IsoFile <String> [-Storage <String>] [-ScsiSlot <Int32>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByComputerName

```
Mount-LWProxmoxIsoImage [-ComputerName] <String[]> [-IsoPath] <String> [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Mounts an ISO file from a Proxmox storage to a virtual machine using the
Proxmox VE API. The ISO is attached via a SCSI interface (scsi30 by default,
to avoid conflicts with disk drives).

Can be invoked with either a ComputerName (lab machine name) or with direct
Proxmox API parameters (Node, VmId, IsoFile).

When Storage is omitted, all ISO-capable storages on the node are searched
automatically to locate the ISO file.

Requires an active connection to the Proxmox cluster.

## EXAMPLES

### Example 1

```powershell
Mount-LWProxmoxIsoImage -ComputerName 'Server01' -IsoPath 'D:\ISOs\setup.iso' -PassThru
```

Mounts the ISO to the lab VM 'Server01' and returns the result with drive letter.

### Example 2

```powershell
Mount-LWProxmoxIsoImage -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'dsc-resources.iso'
```

Mounts the ISO file 'dsc-resources.iso' to VM 9004, automatically
discovering which storage contains the file.

### Example 3

```powershell
Mount-LWProxmoxIsoImage -Node 'rz1pinhst101' -VmId 9004 -IsoFile 'setup.iso' -Storage 'cephfs' -ScsiSlot 29
```

Mounts the ISO from 'cephfs' storage using SCSI slot 29.

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

### -IsoPath

The full path to the ISO file. Only the file name is used to locate the
ISO on the Proxmox storage.

```yaml
Type: String
Parameter Sets: ByComputerName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

When specified, returns the mount result including the drive letter detected
inside the guest operating system.

```yaml
Type: SwitchParameter
Parameter Sets: ByComputerName
Aliases:

Required: False
Position: Named
Default value: False
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

### -IsoFile

The name of the ISO file (e.g. 'dsc-resources.iso'). The file must already
exist on one of the available storages.

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

### -Storage

Optional storage identifier where the ISO file is located. When omitted,
all ISO-capable storages are searched automatically.

```yaml
Type: String
Parameter Sets: ByApiParams
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScsiSlot

The SCSI slot number (0-30) to use for the CD-ROM drive. Defaults to 30,
to avoid conflicts with disk drives that typically use lower slots.

```yaml
Type: Int32
Parameter Sets: ByApiParams
Aliases:

Required: False
Position: Named
Default value: 30
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
