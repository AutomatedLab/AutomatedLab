---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabDefaultVirtualizationEngine

## SYNOPSIS
Set default virtualization engine

## SYNTAX

```
Set-LabDefaultVirtualizationEngine [-VirtualizationEngine] <String> [<CommonParameters>]
```

## DESCRIPTION
Sets the default virtualization engine for the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabDefaultVirtualizationEngine -VirtualizationEngine Azure
```

Sets the lab's virtualization engine to Azure

## PARAMETERS

### -VirtualizationEngine
The virtualization engine to use.
Supported values: HyperV, VMWare, Azure

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
