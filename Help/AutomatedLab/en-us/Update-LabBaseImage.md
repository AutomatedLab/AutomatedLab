---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Update-LabBaseImage

## SYNOPSIS
Update a base image with OS updates

## SYNTAX

```
Update-LabBaseImage -BaseImagePath <String> -UpdateFolderPath <String> [<CommonParameters>]
```

## DESCRIPTION
Update a base image with OS updates

## EXAMPLES

### Example 1
```powershell
PS C:\> Update-LabBaseImage -BaseImagePath "D:\AutomatedLab-VMs\BASE_WindowsServer2016Datacenter(DesktopExperience)_10.0.14393.0.vhdx" -UpdateFolderPath $LabSources/OSUpdates/2016
```

Apply all updates in the 2016 folder to the base image

## PARAMETERS

### -BaseImagePath
Path to VHDX file

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
Path to the updates

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
