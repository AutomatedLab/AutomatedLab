---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Set-LabLocalVirtualMachineDiskAuto

## SYNOPSIS
Set the VM disk container

## SYNTAX

```
Set-LabLocalVirtualMachineDiskAuto [[-SpaceNeeded] <Int64>] [<CommonParameters>]
```

## DESCRIPTION
Automatically determines the disk to store all VMs on by latency.
Boot volumes are only selected if no other volumes are present or if the next drive is more than 50% slower than the boot drive.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabLocalVirtualMachineDiskAuto -SpaceNeeded 20GB
```

Locates a disk with at least 20GB free space to place the VMs on.

## PARAMETERS

### -SpaceNeeded
The space needed for the whole lab installation

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
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
