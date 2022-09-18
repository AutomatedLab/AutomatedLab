---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/Set-LabSnippet
schema: 2.0.0
---

# Set-LabSnippet

## SYNOPSIS
Update a snippet

## SYNTAX

```
Set-LabSnippet [-Name] <String> [[-DependsOn] <String[]>] [[-Type] <String>] [[-Tag] <String[]>]
 [[-ScriptBlock] <ScriptBlock>] [-NoExport] [<CommonParameters>]
```

## DESCRIPTION
Update a snippet

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSnippet -Name Checkpoints | Set-LabSnippet -ScriptBlock {Checkpoint-LabVm -All -SnapshotName (Get-Date -Format yyyyMMddHHmmss)}
```

Modify the scriptblock for the existing snippet Checkpoints

## PARAMETERS

### -DependsOn
Names of snippets that this snippet depends on
in order to work.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Accept pipeline input: True (ByPropertyName, ByValue)
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

Required: False
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

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

