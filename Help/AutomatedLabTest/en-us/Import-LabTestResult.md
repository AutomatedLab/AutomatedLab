---
external help file: AutomatedLabTest-help.xml
Module Name: automatedlabtest
online version:
schema: 2.0.0
---

# Import-LabTestResult

## SYNOPSIS
Import the results from Test-LabDeployment

## SYNTAX

### Path (Default)
```
Import-LabTestResult [-LogDirectory <String>] [<CommonParameters>]
```

### Single
```
Import-LabTestResult [-Path <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Import the results from Test-LabDeployment

## EXAMPLES

### Example 1
```powershell
PS C:\> Import-LabTestResult -LogDirectory $home/Documents
```

Import all test result files in $home/Documents

## PARAMETERS

### -LogDirectory
The directory to import from

```yaml
Type: String
Parameter Sets: Path
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
The single result files to import

```yaml
Type: String[]
Parameter Sets: Single
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
