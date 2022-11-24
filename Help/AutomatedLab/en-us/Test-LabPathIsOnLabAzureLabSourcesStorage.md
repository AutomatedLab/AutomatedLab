---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Test-LabPathIsOnLabAzureLabSourcesStorage
schema: 2.0.0
---

# Test-LabPathIsOnLabAzureLabSourcesStorage

## SYNOPSIS
Tests if a path is on Azure

## SYNTAX

```
Test-LabPathIsOnLabAzureLabSourcesStorage [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
Tests if a given path is inside the Azure lab source storage share

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabPathIsOnLabAzureLabSourcesStorage -Path "$labSources\Tools\SomeTool.exe"
```

Test if the path "$labSources\Tools\SomeTool.exe" is actually located on an Azure
lab sources share.

The dynamic $labSources variable may either point to a local path or an Azure
file share depending on the Hypervisor that is used.

## PARAMETERS

### -Path
The path to check

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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

