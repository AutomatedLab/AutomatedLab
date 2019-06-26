---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Sync-LabAzureLabSources

## SYNOPSIS
Sync local lab sources to Azure

## SYNTAX

```
Sync-LabAzureLabSources [-SkipIsos] [-DoNotSkipOsIsos] [[-MaxFileSizeInMb] <Int32>] [-Filter <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Synchronize your local lab source depot to Azure.
OS ISOs will automatically be skipped, otherwise there are no limitations.
All files are hashed to ensure that no existing files are overwritten

## EXAMPLES

### Example 1
```powershell
PS C:\> Sync-LabAzureLabSources -MaxFileSizeInMb 500 -Filter *.exe
```

Upload all executables smaller than 500MB to Azure

## PARAMETERS

### -SkipIsos
Indicates that ISOs should not be uploaded

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

### -MaxFileSizeInMb
The maximum file size to upload

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotSkipOsIsos
Indicates that OS ISOs should indeed be uploaded to Azure

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

### -Filter
Wildcard filter

```yaml
Type: String
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
