---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabTfsParameter
schema: 2.0.0
---

# Get-LabTfsParameter

## SYNOPSIS
Get relevant connection parameters to connect to TFS/AzDevOps

## SYNTAX

```
Get-LabTfsParameter [-ComputerName] <String> [-Local] [<CommonParameters>]
```

## DESCRIPTION
Get relevant connection parameters to connect to TFS/AzDevOps

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabTfsParameter
```

Get relevant connection parameters to connect to TFS/AzDevOps

## PARAMETERS

### -ComputerName
TFS/Azure DevOps instances

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

### -Local
Indicates that connection details should be local (internal) to the lab environment

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

