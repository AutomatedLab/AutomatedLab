---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/Export-LabSnippet
schema: 2.0.0
---

# Export-LabSnippet

## SYNOPSIS
Export a snippet

## SYNTAX

```
Export-LabSnippet [-Name] <String> [[-DependsOn] <String[]>] [-MetaData] [<CommonParameters>]
```

## DESCRIPTION
Export a snippet

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSnippet Domain,PKI | Export-LabSnippet
```

Export the snippets Domain and PKI

## PARAMETERS

### -DependsOn
The dependencies of the snippet to export

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

### -MetaData
Indicates that snippet metadata psd1 should be exported

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
Name of snippet to export

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

