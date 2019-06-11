---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Invoke-LWCommand

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### FileContentDependencyScriptBlock
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -DependencyFolderPath <String> -ScriptBlock <ScriptBlock> [-KeepFolder] [-ArgumentList <Object[]>]
 [-ParameterVariableName <String>] [-Retries <Int32>] [-RetryIntervalInSeconds <Int32>]
 [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [<CommonParameters>]
```

### FileContentDependencyRemoteScript
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -DependencyFolderPath <String> -ScriptFileName <String> [-KeepFolder] [-ArgumentList <Object[]>]
 [-ParameterVariableName <String>] [-Retries <Int32>] [-RetryIntervalInSeconds <Int32>]
 [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [<CommonParameters>]
```

### FileContentDependencyLocalScript
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -DependencyFolderPath <String> -ScriptFilePath <String> [-KeepFolder] [-ArgumentList <Object[]>]
 [-ParameterVariableName <String>] -Retries <Int32> -RetryIntervalInSeconds <Int32> [-ThrottleLimit <Int32>]
 [-AsJob] [-PassThru] [<CommonParameters>]
```

### NoDependencyLocalScript
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -ScriptFilePath <String> [-ArgumentList <Object[]>] [-ParameterVariableName <String>] -Retries <Int32>
 -RetryIntervalInSeconds <Int32> [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [<CommonParameters>]
```

### IsoImageDependencyLocalScript
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -ScriptFilePath <String> -IsoImagePath <String> [-ArgumentList <Object[]>] [-ParameterVariableName <String>]
 -Retries <Int32> -RetryIntervalInSeconds <Int32> [-ThrottleLimit <Int32>] [-AsJob] [-PassThru]
 [<CommonParameters>]
```

### NoDependencyScriptBlock
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -ScriptBlock <ScriptBlock> [-ArgumentList <Object[]>] [-ParameterVariableName <String>] [-Retries <Int32>]
 [-RetryIntervalInSeconds <Int32>] [-ThrottleLimit <Int32>] [-AsJob] [-PassThru] [<CommonParameters>]
```

### IsoImageDependencyScriptBlock
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -ScriptBlock <ScriptBlock> -IsoImagePath <String> [-ArgumentList <Object[]>] [-ParameterVariableName <String>]
 [-Retries <Int32>] [-RetryIntervalInSeconds <Int32>] [-ThrottleLimit <Int32>] [-AsJob] [-PassThru]
 [<CommonParameters>]
```

### IsoImageDependencyScript
```
Invoke-LWCommand -ComputerName <String[]> -Session <PSSession[]> [-ActivityName <String>]
 -IsoImagePath <String> [-ArgumentList <Object[]>] [-ParameterVariableName <String>] [-ThrottleLimit <Int32>]
 [-AsJob] [-PassThru] [<CommonParameters>]
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DependencyFolderPath
{{ Fill DependencyFolderPath Description }}

```yaml
Type: String
Parameter Sets: FileContentDependencyScriptBlock, FileContentDependencyRemoteScript, FileContentDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsoImagePath
{{ Fill IsoImagePath Description }}

```yaml
Type: String
Parameter Sets: IsoImageDependencyLocalScript, IsoImageDependencyScriptBlock, IsoImageDependencyScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepFolder
{{ Fill KeepFolder Description }}

```yaml
Type: SwitchParameter
Parameter Sets: FileContentDependencyScriptBlock, FileContentDependencyRemoteScript, FileContentDependencyLocalScript
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParameterVariableName
{{ Fill ParameterVariableName Description }}

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

### -Retries
{{ Fill Retries Description }}

```yaml
Type: Int32
Parameter Sets: FileContentDependencyScriptBlock, FileContentDependencyRemoteScript, NoDependencyScriptBlock, IsoImageDependencyScriptBlock
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: FileContentDependencyLocalScript, NoDependencyLocalScript, IsoImageDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryIntervalInSeconds
{{ Fill RetryIntervalInSeconds Description }}

```yaml
Type: Int32
Parameter Sets: FileContentDependencyScriptBlock, FileContentDependencyRemoteScript, NoDependencyScriptBlock, IsoImageDependencyScriptBlock
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: FileContentDependencyLocalScript, NoDependencyLocalScript, IsoImageDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
{{ Fill ScriptBlock Description }}

```yaml
Type: ScriptBlock
Parameter Sets: FileContentDependencyScriptBlock, NoDependencyScriptBlock, IsoImageDependencyScriptBlock
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFileName
{{ Fill ScriptFileName Description }}

```yaml
Type: String
Parameter Sets: FileContentDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFilePath
{{ Fill ScriptFilePath Description }}

```yaml
Type: String
Parameter Sets: FileContentDependencyLocalScript, NoDependencyLocalScript, IsoImageDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session
{{ Fill Session Description }}

```yaml
Type: PSSession[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
