---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Mount-LabIsoImage

## SYNOPSIS
Mount an ISO

## SYNTAX

```
Mount-LabIsoImage [-ComputerName] <String[]> [-IsoPath] <String> [-SupressOutput] [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Mounts a disk image on one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> $location = Mount-LabIsoImage -ComputerName DC01 -IsoPath $labSources\ISOs\mimikatz.iso -PassThru
```

Mounts mimikatz on DC01 and returns the drive letter

## PARAMETERS

### -ComputerName
The computer names

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
The full path of the ISO file to mount

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

### -SupressOutput
Indicates if output should be suppressed

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

### -PassThru
Indicates if a psobject containing drive info should be passed back to the caller

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

## OUTPUTS

## NOTES

## RELATED LINKS
