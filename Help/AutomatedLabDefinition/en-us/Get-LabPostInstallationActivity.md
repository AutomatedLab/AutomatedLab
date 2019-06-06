---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabPostInstallationActivity

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -CustomRole
{{ Fill CustomRole Description }}

```yaml
Type: String
Parameter Sets: CustomRole
Aliases:
Accepted values: AzureStack, DemoCustomRole, Exchange2013, Exchange2016, LabBuilder, MDT, ProGet5, SCCM, WindowsAdminCenter

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DependencyFolder
{{ Fill DependencyFolder Description }}

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

### -IsoImage
{{ Fill IsoImage Description }}

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

### -KeepFolder
{{ Fill KeepFolder Description }}

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

### -ScriptFileName
{{ Fill ScriptFileName Description }}

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

### -ScriptFilePath
{{ Fill ScriptFilePath Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
