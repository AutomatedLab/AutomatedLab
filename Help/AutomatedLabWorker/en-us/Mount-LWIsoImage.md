---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Mount-LWIsoImage

## SYNOPSIS
Mounts an ISO image on a Hyper-V VM

## SYNTAX

```
Mount-LWIsoImage [-ComputerName] <String[]> [-IsoPath] <String> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Mounts an ISO image on a Hyper-V VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Mount-LWIsoImage -ComputerName DC01 -IsoPath $labsources\Tfs2018.iso
```

Mounts the ISO Tfs2018.iso on DC01

## PARAMETERS

### -ComputerName
The Hyper-V lab machine to mount the ISO on

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

### -IsoPath
The path to the ISO. Use $LabSources if possible.

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

### -PassThru
Indicates that the drive letter should be returned

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
