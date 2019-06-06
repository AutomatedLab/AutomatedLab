---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabSoftwarePackage

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### SinglePackage
```
Install-LabSoftwarePackage -Path <String> [-CommandLine <String>] [-Timeout <Int32>] [-CopyFolder <Boolean>]
 -ComputerName <String[]> [-DoNotUseCredSsp] [-AsJob] [-AsScheduledJob]
 [-UseExplicitCredentialsForScheduledJob] [-UseShellExecute] [-ExpectedReturnCodes <Int32[]>] [-PassThru]
 [-NoDisplay] [-ProgressIndicator <Int32>] [<CommonParameters>]
```

### SingleLocalPackage
```
Install-LabSoftwarePackage -LocalPath <String> [-CommandLine <String>] [-Timeout <Int32>]
 [-CopyFolder <Boolean>] -ComputerName <String[]> [-DoNotUseCredSsp] [-AsJob] [-AsScheduledJob]
 [-UseExplicitCredentialsForScheduledJob] [-UseShellExecute] [-ExpectedReturnCodes <Int32[]>] [-PassThru]
 [-NoDisplay] [-ProgressIndicator <Int32>] [<CommonParameters>]
```

### MulitPackage
```
Install-LabSoftwarePackage [-Timeout <Int32>] -Machine <Machine[]> -SoftwarePackage <SoftwarePackage>
 [-DoNotUseCredSsp] [-AsJob] [-AsScheduledJob] [-UseExplicitCredentialsForScheduledJob] [-UseShellExecute]
 [-ExpectedReturnCodes <Int32[]>] [-PassThru] [-NoDisplay] [-ProgressIndicator <Int32>] [<CommonParameters>]
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

### -AsJob
{{ Fill AsJob Description }}

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

### -AsScheduledJob
{{ Fill AsScheduledJob Description }}

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

### -CommandLine
{{ Fill CommandLine Description }}

```yaml
Type: String
Parameter Sets: SinglePackage, SingleLocalPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: SinglePackage, SingleLocalPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CopyFolder
{{ Fill CopyFolder Description }}

```yaml
Type: Boolean
Parameter Sets: SinglePackage, SingleLocalPackage
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseCredSsp
{{ Fill DoNotUseCredSsp Description }}

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

### -ExpectedReturnCodes
{{ Fill ExpectedReturnCodes Description }}

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalPath
{{ Fill LocalPath Description }}

```yaml
Type: String
Parameter Sets: SingleLocalPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Machine
{{ Fill Machine Description }}

```yaml
Type: Machine[]
Parameter Sets: MulitPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoDisplay
{{ Fill NoDisplay Description }}

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
{{ Fill PassThru Description }}

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

### -Path
{{ Fill Path Description }}

```yaml
Type: String
Parameter Sets: SinglePackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressIndicator
{{ Fill ProgressIndicator Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SoftwarePackage
{{ Fill SoftwarePackage Description }}

```yaml
Type: SoftwarePackage
Parameter Sets: MulitPackage
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout
{{ Fill Timeout Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseExplicitCredentialsForScheduledJob
{{ Fill UseExplicitCredentialsForScheduledJob Description }}

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

### -UseShellExecute
{{ Fill UseShellExecute Description }}

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
