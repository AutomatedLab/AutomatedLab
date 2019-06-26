---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Mount-LWAzureIsoImage

## SYNOPSIS
Mount an ISO image on an Azure VM

## SYNTAX

```
Mount-LWAzureIsoImage [-ComputerName] <String[]> [-IsoPath] <String> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Mount an ISO image on an Azure VM. Tries to use the Azure lab sources file share to mount the ISO from
if you are using the dynamic variable $LabSources

## EXAMPLES

### Example 1
```powershell
PS C:\> Mount-LWAzureIsoImage -ComputerName DC01 -IsoPath $LabSources\ISOs\Tfs2018.iso
```

Mounts Tfs2018.iso from the Azure file share on DC01

## PARAMETERS

### -ComputerName
The host to mount the ISO on

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
The path of the ISO. Use $LabSources if possible.

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
