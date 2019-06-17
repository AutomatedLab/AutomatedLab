---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Invoke-LabDscConfiguration

## SYNOPSIS
Invoke a DSC configuration on one or more nodes

## SYNTAX

### New (Default)
```
Invoke-LabDscConfiguration -Configuration <ConfigurationInfo> -ComputerName <String[]>
 [-ConfigurationData <Hashtable>] [-Wait] [<CommonParameters>]
```

### UseExisting
```
Invoke-LabDscConfiguration -ComputerName <String[]> [-UseExisting] [-Wait] [<CommonParameters>]
```

## DESCRIPTION
Invoke a DSC configuration on one or more nodes. Compareable with a push, the configuration
will be applied to the target nodes. The configuration needs to be stored in a file that should
be imported before. Can either deploy a fresh configuration or use an existing one.

## EXAMPLES

### Example 1
```powershell
configuration Baseline
{
    WindowsFeature ADTools
    {
        Name = 'RSAT-AD-Tools'
        Ensure = 'Present'
    }
}

Invoke-LabDscConfiguration -Configuration (Get-Command Baseline) -ComputerName Node1,Node2 -Wait
```

Apply the configuration Baseline on Node1 and Node2

## PARAMETERS

### -ComputerName
The target nodes

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Configuration
The configuration that is stored somewhere. Retrieve with Get-Command

```yaml
Type: ConfigurationInfo
Parameter Sets: New
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationData
The configuration data that should be applied to build the MOF

```yaml
Type: Hashtable
Parameter Sets: New
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseExisting
The parameter UseExisting of Start-DscConfiguration

```yaml
Type: SwitchParameter
Parameter Sets: UseExisting
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
Wait for the configuration to finish

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
