---
external help file: AutomatedLab.Recipe-help.xml
Module Name: AutomatedLab.Recipe
online version: https://automatedlab.org/en/latest/AutomatedLab.Recipe/en-us/Invoke-LabSnippet
schema: 2.0.0
---

# Invoke-LabSnippet

## SYNOPSIS
Invoke one or more lab snippets

## SYNTAX

```
Invoke-LabSnippet [-Name] <String[]> [[-LabParameter] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Invoke one or more lab snippets. If dependencies are used, snippets are executed
in the order calculated.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSnippet Domain,PKI | Invoke-LabSnippet -LabParameter @{DomainName = 'contoso.com'; Name = 'Snippy'}
```

Invoke Domain snippet, then PKI snippet which depends on the domain.
Snippet LabDefinition is auto-added.

## PARAMETERS

### -LabParameter
Parameter hashtable to be supplied to the resulting code.
Check Get-LabSnippet -Syntax for more information.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the snippet to invoke

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

