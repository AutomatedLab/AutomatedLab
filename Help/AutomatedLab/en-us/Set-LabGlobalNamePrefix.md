---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabGlobalNamePrefix

## SYNOPSIS
Set a machine prefix

## SYNTAX

```
Set-LabGlobalNamePrefix [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Sets a prefix to prepend to all machine names

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabGlobalNamePrefix -Name LB
```

Prepends LB to all VMs, e.g. LBDC01

## PARAMETERS

### -Name
The prefix

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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
