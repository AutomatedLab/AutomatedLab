---
external help file: AutomatedLab-help.xml
Module Name: automatedlab
online version:
schema: 2.0.0
---

# Set-LabDscLocalConfigurationManagerConfiguration

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Set-LabDscLocalConfigurationManagerConfiguration [-ComputerName] <String[]> [[-ActionAfterReboot] <String>]
 [[-CertificateID] <String>] [[-ConfigurationID] <String>] [[-RefreshFrequencyMins] <Int32>]
 [[-AllowModuleOverwrite] <Boolean>] [[-DebugMode] <String>] [[-ConfigurationNames] <String[]>]
 [[-StatusRetentionTimeInDays] <Int32>] [[-RefreshMode] <String>] [[-ConfigurationModeFrequencyMins] <Int32>]
 [[-ConfigurationMode] <String>] [[-RebootNodeIfNeeded] <Boolean>]
 [[-ConfigurationRepositoryWeb] <Hashtable[]>] [[-ReportServerWeb] <Hashtable[]>]
 [[-PartialConfiguration] <Hashtable[]>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ActionAfterReboot
{{ Fill ActionAfterReboot Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: ContinueConfiguration, StopConfiguration

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowModuleOverwrite
{{ Fill AllowModuleOverwrite Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateID
{{ Fill CertificateID Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

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

### -ConfigurationID
{{ Fill ConfigurationID Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationMode
{{ Fill ConfigurationMode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: ApplyAndAutoCorrect, ApplyOnly, ApplyAndMonitor

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationModeFrequencyMins
{{ Fill ConfigurationModeFrequencyMins Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationNames
{{ Fill ConfigurationNames Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationRepositoryWeb
{{ Fill ConfigurationRepositoryWeb Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugMode
{{ Fill DebugMode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: ForceModuleImport, All, None

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartialConfiguration
{{ Fill PartialConfiguration Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RebootNodeIfNeeded
{{ Fill RebootNodeIfNeeded Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshFrequencyMins
{{ Fill RefreshFrequencyMins Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshMode
{{ Fill RefreshMode Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Push, Pull

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportServerWeb
{{ Fill ReportServerWeb Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatusRetentionTimeInDays
{{ Fill StatusRetentionTimeInDays Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
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
