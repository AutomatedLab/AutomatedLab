---
external help file: AutomatedLabDefinition.Help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabPostInstallationActivity

## SYNOPSIS
Get post-installation activity

## SYNTAX

### FileContentDependencyLocalScript
```
Get-LabPostInstallationActivity -DependencyFolder <String> [-KeepFolder] -ScriptFilePath <String>
 [-DoNotUseCredSsp] [<CommonParameters>]
```

### FileContentDependencyRemoteScript
```
Get-LabPostInstallationActivity -DependencyFolder <String> [-KeepFolder] -ScriptFileName <String>
 [-DoNotUseCredSsp] [<CommonParameters>]
```

### IsoImageDependencyLocalScript
```
Get-LabPostInstallationActivity -IsoImage <String> -ScriptFilePath <String> [-DoNotUseCredSsp]
 [<CommonParameters>]
```

### IsoImageDependencyRemoteScript
```
Get-LabPostInstallationActivity -IsoImage <String> -ScriptFileName <String> [-DoNotUseCredSsp]
 [<CommonParameters>]
```

### CustomRole
```
Get-LabPostInstallationActivity [-KeepFolder] [-Properties <Hashtable>] [-DoNotUseCredSsp]
 [-CustomRole <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns a new post-installation activity that can be attached to machines

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DependencyFolder
A folder of dependency files if necessary

```yaml
Type: String
Parameter Sets: FileContentDependencyLocalScript, FileContentDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepFolder
Indicates that the target folder should be kept on the machine

```yaml
Type: SwitchParameter
Parameter Sets: FileContentDependencyLocalScript, FileContentDependencyRemoteScript, CustomRole
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFilePath
The script file path of the script that is executed

```yaml
Type: String
Parameter Sets: FileContentDependencyLocalScript, IsoImageDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFileName
The remote script file name

```yaml
Type: String
Parameter Sets: FileContentDependencyRemoteScript, IsoImageDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsoImage
The ISO image that should be mounted during post-installation

```yaml
Type: String
Parameter Sets: IsoImageDependencyLocalScript, IsoImageDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomRole
{{ Fill CustomRole Description }}

```yaml
Type: String
Parameter Sets: CustomRole
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

### -Properties
{{ Fill Properties Description }}

```yaml
Type: Hashtable
Parameter Sets: CustomRole
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
