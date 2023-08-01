---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/New-LabVHDX
schema: 2.0.0
---

# New-LabVHDX

## SYNOPSIS
Create new VHDX

## SYNTAX

### ByName
```
New-LabVHDX -Name <String[]> [<CommonParameters>]
```

### All
```
New-LabVHDX [-All] [<CommonParameters>]
```

## DESCRIPTION
Creates new VHDX files for the lab and initializing them with NTFS and a partition called Data

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabVHDX -All
```

Creates new VHDX files for the lab and initializing them with NTFS and a partition called Data

## PARAMETERS

### -All
Indicates if all disks defined in the lab should be created

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
The names of the VHDX files to create

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

