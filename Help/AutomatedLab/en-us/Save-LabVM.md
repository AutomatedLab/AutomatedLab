---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Save-LabVM

## SYNOPSIS
Save a VM

## SYNTAX

### ByName (Default)
```
Save-LabVM [-Name] <String[]> [<CommonParameters>]
```

### ByRole
```
Save-LabVM -RoleName <Roles> [<CommonParameters>]
```

### All
```
Save-LabVM [-All] [<CommonParameters>]
```

## DESCRIPTION
Saves the state of a lab machine on HyperV and VMWare

## EXAMPLES

### Example 1
```powershell
PS C:\> Save-LabVm -All
```

Save the state of all running VMs

## PARAMETERS

### -Name
The machine names

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RoleName
The roles of the machines to be saved

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Indicates that all machines should be saved

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
