---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabWindowsFeature

## SYNOPSIS
Get Windows feature status

## SYNTAX

```
Get-LabWindowsFeature [-ComputerName] <String[]> [[-FeatureName] <String[]>] [-UseLocalCredential]
 [[-ProgressIndicator] <Int32>] [-NoDisplay] [-AsJob] [<CommonParameters>]
```

## DESCRIPTION
Gets the status of one or more Windows features on one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabWindowsFeature DC01,FS01 -FeatureName RSAT-AD-Tools
```

Get the installation status of the optional feature RSAT-AD-Tools on DC01 and FS01

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

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalCredential
Indicates whether local credentials should be used

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
