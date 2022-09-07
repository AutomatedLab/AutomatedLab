---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabSourcesLocationInternal
schema: 2.0.0
---

# Get-LabSourcesLocationInternal

## SYNOPSIS
Internal cmdlet to retrieve lab sources location

## SYNTAX

```
Get-LabSourcesLocationInternal [-Local] [<CommonParameters>]
```

## DESCRIPTION
Internal cmdlet to retrieve lab sources location

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabSourcesLocationInternal
```

Retrieve the lab sources location depending on the chosen Hypervisor

## PARAMETERS

### -Local
Skip Hypervisor detection and simply use the local folder

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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

