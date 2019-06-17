---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Invoke-LabCommand

## SYNOPSIS
Invoke command on a lab vm

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
Invokes a script block or a script file on a lab VM with the ability to add function definitions and variables for the script block to use.
Scripts and script blocks can also use a dependency folder containing dependencies.

## EXAMPLES

### Example 1


```powershell
$ALocallyDefinedVariable = "This is a"
$AndAnother = "Test"
function Get-SomeThingOnMyLocalMachine
{
    Write-Host "$ALocallyDefinedVariable $AndAnother"
}

Invoke-LabCommand -ActivityName GetStuff -ComputerName DC1 -ScriptBlock {Get-SomeThingOnMyLocalMachine} -Variable ALocallyDefinedVariable,AndAnother -Function (Get-Command Get-SomeThingOnMyLocalMachine) -UseLocalCredential -Retries 3 -RetryIntervalInSeconds 20
```

Invokes a script block calling a locally-defined function on the machine DC1.
The locally-defined function as well as the two local variables are passed to the VM before the script block is executed

## PARAMETERS

### -ActivityName
The name of the activity to execute

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

### -PostInstallationActivity
Indicates if the post installation activities defined in the lab should be processed instead of a script block

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

### -ComputerName
The computer names

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

### -ArgumentList
The argument list for the script block or the script

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

### -UseLocalCredential
Indicates if the machines' local credentials should be used

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

### -Credential
The credential that should be used

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

### -Variable
The names of the variables to add to the sessions executing the lab command

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

### -Function
The function definitions to add to the sessions executing the lab command

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

### -ThrottleLimit
The amount of parallel jobs to create

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
Indicates if the resulting jobs should be passed back to the caller

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

### -ScriptBlock
The script block to execute on the machines

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

### -Retries
The number of retries in case the script block fails

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
The amount of seconds to wait between each retry

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

### -FilePath
The script file path if a script file should be used

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

### -DependencyFolderPath
The folder containing the files the script or the script block depend on

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

### -FileName
The script file to execute

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

### -CustomRoleName
The custom role that should be deployed, e.g. ProGet

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
