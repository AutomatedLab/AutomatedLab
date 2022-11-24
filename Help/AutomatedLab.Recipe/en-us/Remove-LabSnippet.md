---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/Remove-LabSnippet
schema: 2.0.0
---

# Remove-LabSnippet

## SYNOPSIS
Remove one or more snippets

## SYNTAX

```
Remove-LabSnippet [-Name] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Remove one or more snippets

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSnippet -Type CustomRole | Remove-LabSnippet
```

Remove all Custom Role snippets

## PARAMETERS

### -Name
Name of the snippet

```yaml
Type: String[]
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

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

