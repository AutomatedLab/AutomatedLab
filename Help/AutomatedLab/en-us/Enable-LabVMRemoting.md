---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Enable-LabVMRemoting

## SYNOPSIS
Enable remoting on machines

## SYNTAX

### ByName
```
Enable-LabVMRemoting -ComputerName <String[]> [<CommonParameters>]
```

### All
```
Enable-LabVMRemoting [-All] [<CommonParameters>]
```

## DESCRIPTION
Enables remoting on one or more lab machines on Azure, HyperV and VMWare

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabVMRemoting
```

Enable Windows Remote Management on lab VMs

## PARAMETERS

### -ComputerName
The computer names

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -All
Indicates whether all lab machines should be used

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
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
