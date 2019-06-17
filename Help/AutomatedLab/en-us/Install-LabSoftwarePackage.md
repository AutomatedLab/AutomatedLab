---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Install-LabSoftwarePackage

## SYNOPSIS
Install software

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
Installs a lab software package on one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
The source path of the package to install

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

### -CommandLine
The package command line

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

### -Timeout
The installation timeout in minutes

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

### -CopyFolder
Indicates if the parent folder of the software package should be copied entirely to the target machine

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

### -ComputerName
The computer names

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

### -PassThru
Indicates if the results should be passed back to the caller

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

### -ProgressIndicator
Every n seconds, print a . to the console

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

### -LocalPath
The local path on the target machine

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
The lab machines

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

### -SoftwarePackage
The lab software package

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

### -DoNotUseCredSsp
Indicates that CredSSP should not be used

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
Indicates that the installation should be executed in a scheduled job, if it does not work otherwise

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
Indicates that the ProcessStartInfo property UseShellExecute should be used

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
The list of expected return codes, e.g. 0,3010

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

### -UseExplicitCredentialsForScheduledJob
Use credentials instead of logged on account for the scheduled job

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
