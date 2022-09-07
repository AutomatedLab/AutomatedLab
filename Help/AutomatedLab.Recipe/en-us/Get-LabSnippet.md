---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/Get-LabSnippet
schema: 2.0.0
---

# Get-LabSnippet

## SYNOPSIS
Get a (filtered) list of lab code snippets

## SYNTAX

```
Get-LabSnippet [[-Name] <String[]>] [[-Description] <String>] [[-Type] <String>] [[-Tag] <String[]>] [-Syntax]
 [<CommonParameters>]
```

## DESCRIPTION
Get a (filtered) list of lab code snippets.
Returns both built-in as well as user-defined
sample scripts and snippets

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSnippet -Name *Domain*
```

Return all Domain snippets

### Example 2
```powershell
PS C:\> Get-LabSnippet -Type Sample
```

Return all sample script snippets

## PARAMETERS

### -Description
Filter by description (wildcard)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Filter by Name

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Syntax
Display syntax for specific code block

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

### -Tag
Filter by one or more tags

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
Filter by type

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

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

