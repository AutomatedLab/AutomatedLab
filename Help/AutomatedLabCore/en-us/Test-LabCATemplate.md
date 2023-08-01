---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Test-LabCATemplate
schema: 2.0.0
---

# Test-LabCATemplate

## SYNOPSIS
Test CA template existence

## SYNTAX

```
Test-LabCATemplate [-TemplateName] <String> [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Tests if the specified certificate template exists

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabCATemplate -TemplateName WebServer -ComputerName (Get-LabIssuingCa)
```

Check if the WebServer template exists on the lab issuing CA

## PARAMETERS

### -ComputerName
The machine to check for template existence on

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

### -TemplateName
The template name (common name)

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

