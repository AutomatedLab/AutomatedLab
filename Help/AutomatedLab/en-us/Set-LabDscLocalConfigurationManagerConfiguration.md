---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabDscLocalConfigurationManagerConfiguration

## SYNOPSIS
Set LCM settings for a node

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
Set LCM settings for a node. Supports all parameters of the Settings resource

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabDscLocalConfigurationManagerConfiguration -RebootNodeIfNeeded $trure -ComputerName (Get-LabVm)
```

Sets the LCM to reboot on all lab VMs

## PARAMETERS

### -ActionAfterReboot
What to do after a node has restarted

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
Allow overwriting modules with data from the configuration or resource repository

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
The certificate thumbprint to decrypt configurations

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
The hosts to configure

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
The GUID of the configuration (PS v4)

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
The desired configuration mode

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
The configuration mode interval. Minimum is 15

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
The configurations to pull from a pull server

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
The pull server

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
Debugging settings

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
Partial configurations to apply

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
Indicates that the node will automatically reboot if a resource expects it to

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
Refresh frequency. Minimum is 30

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
Refresh mode, Push or Pull

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
The report server to select

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
The status retention time

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
