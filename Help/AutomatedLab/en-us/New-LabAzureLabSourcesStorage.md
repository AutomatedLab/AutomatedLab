---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabAzureLabSourcesStorage

## SYNOPSIS
Create Azure lab source storage

## SYNTAX

```
New-LabAzureLabSourcesStorage [[-LocationName] <String>] [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Creates the resource group AutomatedLabSources and a random storage account with a file share called labsources on it in your subscription

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabAzureLabSourcesStorage -LocationName westeurope
```

Creates the resource group AutomatedLabSources and a random storage account with a file share called labsources on it in your subscription

## PARAMETERS

### -LocationName
The location to store the lab sources in. Defaults to lab location

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

### -NoDisplay
Indicates that no text should be displayed on the console host

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
