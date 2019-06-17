---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-LabDscLocalConfigurationManagerConfiguration

## SYNOPSIS
Reset the LCM configuration of a lab VM

## SYNTAX

```
Remove-LabDscLocalConfigurationManagerConfiguration [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Reset the LCM configuration of a lab VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabDscLocalConfigurationManagerConfiguration -ComputerName DC01
```

Reset the LCM config of DC01 to the defaults

## PARAMETERS

### -ComputerName
The nodes to reset

```yaml
Type: String[]
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
