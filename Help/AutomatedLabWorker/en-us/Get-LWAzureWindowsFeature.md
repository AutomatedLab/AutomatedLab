---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureWindowsFeature

## SYNOPSIS
List installed Windows features on an Azure VM

## SYNTAX

```
Get-LWAzureWindowsFeature [-Machine] <Machine[]> [-FeatureName] <String[]> [-UseLocalCredential] [-AsJob]
 [<CommonParameters>]
```

## DESCRIPTION
List installed Windows features on an Azure VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureWindowsFeature -Machine HostA -FeatureName Microsoft-Hyper-V-All
```

Retrieves the status of the optional feature Hyper-V from the Azure VM HostA

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
The name of the feature

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
The name of the machine

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
Indicates that a local account should be used to connect

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
