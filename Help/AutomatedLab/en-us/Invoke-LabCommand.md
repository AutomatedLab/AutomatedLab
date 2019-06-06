---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Invoke-LabCommand

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### PostInstallationActivity
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> [-PostInstallationActivity]
 [-CustomRoleName <String[]>] [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential]
 [-Credential <PSCredential>] [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-ThrottleLimit <Int32>]
 [-AsJob] [-PassThru] [-NoDisplay] [<CommonParameters>]
```

### ScriptBlock
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> [-ScriptBlock] <ScriptBlock>
 [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential] [-Credential <PSCredential>]
 [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-Retries <Int32>] [-RetryIntervalInSeconds <Int32>]
 [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [-NoDisplay] [<CommonParameters>]
```

### Script
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> -FilePath <String>
 [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential] [-Credential <PSCredential>]
 [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-Retries <Int32>] [-RetryIntervalInSeconds <Int32>]
 [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [-NoDisplay] [<CommonParameters>]
```

### ScriptFileNameContentDependency
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> -FileName <String>
 [-DependencyFolderPath <String>] [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential]
 [-Credential <PSCredential>] [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-Retries <Int32>]
 [-RetryIntervalInSeconds <Int32>] [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [-NoDisplay]
 [<CommonParameters>]
```

### ScriptFileContentDependency
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> -FilePath <String>
 -DependencyFolderPath <String> [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential]
 [-Credential <PSCredential>] [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-Retries <Int32>]
 [-RetryIntervalInSeconds <Int32>] [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [-NoDisplay]
 [<CommonParameters>]
```

### ScriptBlockFileContentDependency
```
Invoke-LabCommand [-ActivityName <String>] [-ComputerName] <String[]> [-ScriptBlock] <ScriptBlock>
 -DependencyFolderPath <String> [-ArgumentList <Object[]>] [-DoNotUseCredSsp] [-UseLocalCredential]
 [-Credential <PSCredential>] [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-Retries <Int32>]
 [-RetryIntervalInSeconds <Int32>] [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [-NoDisplay]
 [<CommonParameters>]
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

### -ActivityName
{{ Fill ActivityName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ArgumentList
{{ Fill ArgumentList Description }}

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

### -Credential
{{ Fill Credential Description }}

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomRoleName
{{ Fill CustomRoleName Description }}

```yaml
Type: String[]
Parameter Sets: PostInstallationActivity
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DependencyFolderPath
{{ Fill DependencyFolderPath Description }}

```yaml
Type: String
Parameter Sets: ScriptFileNameContentDependency
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ScriptFileContentDependency, ScriptBlockFileContentDependency
Aliases:

Required: True
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

### -FileName
{{ Fill FileName Description }}

```yaml
Type: String
Parameter Sets: ScriptFileNameContentDependency
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
{{ Fill FilePath Description }}

```yaml
Type: String
Parameter Sets: Script, ScriptFileContentDependency
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Function
{{ Fill Function Description }}

```yaml
Type: FunctionInfo[]
Parameter Sets: (All)
Aliases:

Required: False
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

### -PostInstallationActivity
{{ Fill PostInstallationActivity Description }}

```yaml
Type: SwitchParameter
Parameter Sets: PostInstallationActivity
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Retries
{{ Fill Retries Description }}

```yaml
Type: Int32
Parameter Sets: ScriptBlock, Script, ScriptFileNameContentDependency, ScriptFileContentDependency, ScriptBlockFileContentDependency
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryIntervalInSeconds
{{ Fill RetryIntervalInSeconds Description }}

```yaml
Type: Int32
Parameter Sets: ScriptBlock, Script, ScriptFileNameContentDependency, ScriptFileContentDependency, ScriptBlockFileContentDependency
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
{{ Fill ScriptBlock Description }}

```yaml
Type: ScriptBlock
Parameter Sets: ScriptBlock, ScriptBlockFileContentDependency
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleLimit
{{ Fill ThrottleLimit Description }}

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

### -UseLocalCredential
{{ Fill UseLocalCredential Description }}

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

### -Variable
{{ Fill Variable Description }}

```yaml
Type: PSVariable[]
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
