---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabWindowsFeature

## SYNOPSIS
Install a Windows feature

## SYNTAX

```
Install-LabWindowsFeature [-ComputerName] <String[]> [-FeatureName] <String[]> [-IncludeAllSubFeature]
 [-IncludeManagementTools] [-UseLocalCredential] [[-ProgressIndicator] <Int32>] [-NoDisplay] [-PassThru]
 [-AsJob] [<CommonParameters>]
```

## DESCRIPTION
Installs one or more Windows features on one or more lab machines

## EXAMPLES

### Example 1


```powershell
Install-LabWindowsFeature -ComputerName (Get-LabVM -Running) -FeatureName RSAT -IncludeAllSubFeature
```

Installs the full Remote Server Admin Tools on all running lab machines

## PARAMETERS

### -ComputerName
The computer names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FeatureName
The feature names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAllSubFeature
Indicates if all subfeatures for the selected features should be installed

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

### -UseLocalCredential
Indicates whether the machine's local credentials should be used

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

### -ProgressIndicator
Every n seconds, print a . to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDisplay
Indicates if output should be suppressed

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

### -PassThru
Indicates if the resulting jobs should be passed back to the caller

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

### -AsJob
Indicates that the cmdlet should run in the background

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

### -IncludeManagementTools
Indicates that the management tools should be included

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
