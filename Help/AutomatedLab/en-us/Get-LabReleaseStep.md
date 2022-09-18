---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabReleaseStep
schema: 2.0.0
---

# Get-LabReleaseStep

## SYNOPSIS
Get all possible release steps of a TFS/Azure DevOps release pipeline

## SYNTAX

```
Get-LabReleaseStep [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get all possible release steps of a TFS/Azure DevOps release pipeline

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabReleaseStep
```

List all possible release steps from the first Azure DevOps/TFS Server in the lab

## PARAMETERS

### -ComputerName
The TFS/Azure DevOps host

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

