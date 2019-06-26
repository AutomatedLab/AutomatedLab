---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVHDX

## SYNOPSIS
Get lab disks

## SYNTAX

### ByName
```
Get-LabVHDX -Name <String[]> [<CommonParameters>]
```

### All
```
Get-LabVHDX [-All] [<CommonParameters>]
```

## DESCRIPTION
Gets lab disk files either by name or returns all lab disks

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVhdx
```

Return all lab VHDX files

## PARAMETERS

### -Name
Name of the VHDX file

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Switch parameter to return all disks

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
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
