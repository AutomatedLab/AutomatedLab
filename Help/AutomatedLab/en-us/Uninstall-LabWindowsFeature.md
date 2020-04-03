---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Uninstall-LabWindowsFeature

## SYNOPSIS
Uninstalls a Windowsfeature of one or more Lab Machines

## SYNTAX

```
Uninstall-LabWindowsFeature [-ComputerName] <String[]> [-FeatureName] <String[]> [-IncludeManagementTools]
 [-UseLocalCredential] [[-ProgressIndicator] <Int32>] [-NoDisplay] [-PassThru] [-AsJob] [<CommonParameters>]
```

## DESCRIPTION
Uninstalls a Windowsfeature of one or more Lab Machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Uninstall-LabWindowsFeature -ComputerName FS1,FS2 -FeatureName FS-DFS-Replication -IncludeManagementTools
```

Removes DFSR from FS1 and FS2

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

### -IncludeManagementTools
Indicates if Management Tools should also be uninstalled.

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
Indicates if the result should be returned to the user.

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
