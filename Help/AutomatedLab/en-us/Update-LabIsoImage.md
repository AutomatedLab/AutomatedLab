---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Update-LabIsoImage
schema: 2.0.0
---

# Update-LabIsoImage

## SYNOPSIS
Update an ISO

## SYNTAX

```
Update-LabIsoImage -SourceIsoImagePath <String> -TargetIsoImagePath <String> -UpdateFolderPath <String>
 -SourceImageIndex <Int32> [-SkipSuperseededCleanup] [<CommonParameters>]
```

## DESCRIPTION
Updates a lab iso image by adding installable hotfixes from a location to the ISO and saving it

## EXAMPLES

### Example 1
```powershell
PS C:\> Update-LabIsoImage -SourceIsoImagePath $labSources\ISOs\en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso `
-TargetIsoImagePath $labSources\ISOs\UpdatedServer2012R2.iso `
-UpdateFolderPath $labSources\OSUpdates\2012R2 `
-SourceImageIndex 4
```

Update the ISO for server 2012 R2 in LabSources with updates from
the referenced folder. The image to be updated is index 4

## PARAMETERS

### -SkipSuperseededCleanup
Skip superseeded updates cleanup

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceImageIndex
The image index of the edition to update

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

### -SourceIsoImagePath
The source ISO

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

### -TargetIsoImagePath
The target ISO

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

### -UpdateFolderPath
The folder containing the updates

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

