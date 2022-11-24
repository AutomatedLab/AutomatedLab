---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/New-LabSnippet
schema: 2.0.0
---

# New-LabSnippet

## SYNOPSIS
Create a new snippet, sample or custom role

## SYNTAX

```
New-LabSnippet [-Name] <String> [-Description] <String> [-Type] <String> [[-Tag] <String[]>]
 [-ScriptBlock] <ScriptBlock> [[-DependsOn] <String[]>] [-Force] [-NoExport] [<CommonParameters>]
```

## DESCRIPTION
Create a new snippet, sample or custom role for use with AutomatedLab.
Uses the configured snippet store Get-PSFConfig -FullName AutomatedLab.Recipe.SnippetStore

If Azure is used as store, be aware that importing snippets takes longer.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabSnippet -Name Checkpoints -Description 'Create checkpoints' -Type Snippet -Tag Checkpoints, Standalone -ScriptBlock {Checkpoint-LabVm -All -SnapshotName 'SnippetShot'}
```

Create a new snippet called Checkpoints, which creates a checkpoint for all
lab VMs.

## PARAMETERS

### -DependsOn
Names of snippets that this snippet depends on
in order to work.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the snippet, searchable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrite existing snippet

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

### -Name
Name of snippet, searchable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoExport
Indicates that the snippet should not be stored on disk/Azure

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
Code that the snippet executes

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
List of tags, searchable

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Type of snippet

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Sample, Snippet, CustomRole

Required: True
Position: 2
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

