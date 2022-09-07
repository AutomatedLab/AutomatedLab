---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Export-LabDefinition
schema: 2.0.0
---

# Export-LabDefinition

## SYNOPSIS
Export lab as XML

## SYNTAX

```
Export-LabDefinition [-Force] [-ExportDefaultUnattendedXml] [-Silent] [<CommonParameters>]
```

## DESCRIPTION
Exports the whole lab definition as XML files in the standard path $env:ProgramData\AutomatedLab\Labs

## EXAMPLES

### Example 1
```powershell
PS C:\> Export-LabDefinition -Force
```

Export the current lab definition (Get-LabDefinition, Get-Lab) to $env:ProgramData\AutomatedLab\Labs, overwriting any existing files

## PARAMETERS

### -ExportDefaultUnattendedXml
Export the unattend.xml for all machines as well

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

### -Force
Overwrite existing XML files

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

### -Silent
Do not display any output

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

