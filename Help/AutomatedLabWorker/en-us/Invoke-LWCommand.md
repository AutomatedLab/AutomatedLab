---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Invoke-LWCommand

## SYNOPSIS
Cmdlet executed by Invoke-LabCommand

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
Executes code on remote hosts. Has various modes of operation like transmitting dependency content or executing scripts on the remote host.

## EXAMPLES

### Example 1
```powershell
PS C:\> Invoke-LWCommand -ComputerName Host1 -ScriptFilePath C:\StartDeployment.ps1 -Retries 3 -RetryInterval 10
```

Executes the script StartDeployment.ps1 which exists on the remote host Host1 with up to 3 retries and a
retry interval of 10 seconds.

## PARAMETERS

### -ActivityName
Name of the activity. Relevant for logging and display

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
The list of arguments to pass to script

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

### -ComputerName
The host to execute the code on

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
The dependencies that should be copied to the VM

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
UNUSED

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
Indicates that the files copied to the remote host should not be removed

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
The name of the variable containing the parameters to pass

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
Indicates that the result should be returned

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
The number of retries

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
The interval between retries

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
The script block to execute

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
The name of the local script to execute remotely

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
The path of the local script

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
The session to execute the code in

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
The throttle limit for Invoke-Command

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
