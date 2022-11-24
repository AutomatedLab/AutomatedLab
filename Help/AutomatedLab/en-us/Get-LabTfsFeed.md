---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabTfsFeed
schema: 2.0.0
---

# Get-LabTfsFeed

## SYNOPSIS
List or locate Artifact feed details of an Azure DevOps/TFS instance

## SYNTAX

```
Get-LabTfsFeed [-ComputerName] <String> [[-FeedName] <String>] [<CommonParameters>]
```

## DESCRIPTION
List or locate Artifact feed details of an Azure DevOps/TFS instance

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabTfsFeed -ComputerName ADO001 -FeedName PowerShell -ErrorAction SilentlyContinue
```

Find a feed called PowerShell on ADO001

## PARAMETERS

### -ComputerName
The lab machine (or reference) hosting the Azure DevOps role

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

### -FeedName
Name of the feed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

