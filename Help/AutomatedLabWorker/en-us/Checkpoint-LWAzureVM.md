---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Checkpoint-LWAzureVM

## SYNOPSIS
Create a snapshot of an Azure VM

## SYNTAX

```
Checkpoint-LWAzureVM [-ComputerName] <String[]> [-SnapshotName] <String> [<CommonParameters>]
```

## DESCRIPTION
Create a snapshot of an Azure VM that uses managed disks

## EXAMPLES

### Example 1
```powershell
PS C:\> Checkpoint-LWAzureVM -ComputerName (Get-LabVm) -SnapshotName AfterInstall
```

Creates a snapshot called AfterInstall for all Azure lab VMs

## PARAMETERS

### -ComputerName
The machines to snapshot

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

### -SnapshotName
The name of the snapshot. Will be added as a Tag to the resource

```yaml
Type: String
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
