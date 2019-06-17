---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Show-LabDeploymentSummary

## SYNOPSIS
Show installation time

## SYNTAX

```
Show-LabDeploymentSummary [-Detailed] [<CommonParameters>]
```

## DESCRIPTION
Shows the lab installation time.
AutomatedLab keeps track of the time it took from the first lab command to the execution of Show-LabDeploymentSummary

## EXAMPLES

### Example 1
```powershell
PS C:\> Show-LabDeploymentSummary -Detailed
```

Display all necessary bits of information on the current lab deployment, including helpful cmdlets to get started

## PARAMETERS

### -Detailed
Indicates that a detailed summary should be displayed

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
