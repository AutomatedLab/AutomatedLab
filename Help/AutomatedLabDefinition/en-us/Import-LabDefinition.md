---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Import-LabDefinition
schema: 2.0.0
---

# Import-LabDefinition

## SYNOPSIS
Import an existing lab definition to extend it later on.

## SYNTAX

### ByName (Default)
```
Import-LabDefinition [-Name] <String> [-PassThru] [<CommonParameters>]
```

### ByPath
```
Import-LabDefinition [-Path] <String> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Import an existing lab definition to extend it later on.

## EXAMPLES

### Example 1
```powershell
PS C:\> $labDefinition = Import-LabDefinition -Name POSH -PassThru
```

Imports the lab named POSH and stores the definition in a variable.

## PARAMETERS

### -Name
Name of the exported lab to import.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the imported data should be returned

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to the lab definition files.

```yaml
Type: String
Parameter Sets: ByPath
Aliases:

Required: True
Position: 1
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

