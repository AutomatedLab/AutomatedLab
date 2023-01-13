---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Remove-LabVM
schema: 2.0.0
---

# Remove-LabVM

## SYNOPSIS
Remove a VM

## SYNTAX

### ByName (Default)
```
Remove-LabVM -ComputerName <String[]> [<CommonParameters>]
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

### -All
Indicates that all lab machines are going to be removed

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The lab VMs to remove

```yaml
Type: String[]
Parameter Sets: ByName
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

