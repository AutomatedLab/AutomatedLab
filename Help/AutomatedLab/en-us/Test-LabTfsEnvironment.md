---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Test-LabTfsEnvironment
schema: 2.0.0
---

# Test-LabTfsEnvironment

## SYNOPSIS
Test lab TFS/Azure DevOps deployment

## SYNTAX

```
Test-LabTfsEnvironment [-ComputerName] <String> [-SkipServer] [-SkipWorker] [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Test lab TFS/Azure DevOps deployment

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabTfsEnvironment -ComputerName AZDO001 -SkipWorker
```

Test lab TFS/Azure DevOps deployment on AZDO001, while ignoring the build worker status

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

### -NoDisplay
Indicates that no messages are displayed

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

### -SkipServer
Indicates that server deployment should be ignored

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

### -SkipWorker
Indicates that build worker deployment should be ignored

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

