---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabAzureLabSourcesContent

## SYNOPSIS
Get the file content of the Azure lab sources file share

## SYNTAX

```
Get-LabAzureLabSourcesContent [[-RegexFilter] <String>] [-File] [-Directory] [<CommonParameters>]
```

## DESCRIPTION
Get the file content of the Azure lab sources file share. Capable of Regex filtering

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureLabSourcesContent -RegexFilter '\.iso' -File
```

Get all ISO files in the Azure lab sources file share

## PARAMETERS

### -Directory
Indicates that only directories (Data type Microsoft.Azure.Storage.File.CloudFileDirectory) should be returned

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

### -File
INdicates that only files (data type Microsoft.Azure.Storage.File.CloudFile) should be returned

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

### -RegexFilter
The regular expression to filter the list of files on

```yaml
Type: String
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
