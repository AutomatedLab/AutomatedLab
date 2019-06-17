---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWHypervWindowsFeature

## SYNOPSIS
Get Windows features from a Hyper-V VM

## SYNTAX

```
Get-LWHypervWindowsFeature [-Machine] <Machine[]> [-FeatureName] <String[]> [-UseLocalCredential] [-AsJob]
 [<CommonParameters>]
```

## DESCRIPTION
Get Windows features from a Hyper-V VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervWindowsFeature -Machine DC01 -FeatureName FS-DFS-Replication -AsJob
```

In a background job, get the status of the feature FS-DFS-Replication on DC01

## PARAMETERS

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

### -FeatureName
Name of the feature

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

### -Machine
Name of the VM

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalCredential
Indicates that a local administrative account should be used

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
