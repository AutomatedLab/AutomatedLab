---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-LabVM

## SYNOPSIS
Remove a VM

## SYNTAX

### ByName
```
Remove-LabVM [-Name] <String[]> [<CommonParameters>]
```

### All
```
Remove-LabVM [-All] [<CommonParameters>]
```

## DESCRIPTION
Removes a lab machine from the current lab.
All existing sessions are removed as well as the existing entries in the hosts file

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabVm -Name SQL01
```

Removes one machine from the running lab so that Install-Lab can recreate it.

## PARAMETERS

### -Name
The machine name

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Indicates that all lab machines are going to be removed

```yaml
Type: SwitchParameter
Parameter Sets: All
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
