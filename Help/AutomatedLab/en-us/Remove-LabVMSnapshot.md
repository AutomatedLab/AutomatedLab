---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Remove-LabVMSnapshot

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### ByNameSnapshotByName
```
Remove-LabVMSnapshot -ComputerName <String[]> -SnapshotName <String> [<CommonParameters>]
```

### ByNameAllSnapShots
```
Remove-LabVMSnapshot -ComputerName <String[]> [-AllSnapShots] [<CommonParameters>]
```

### AllMachinesSnapshotByName
```
Remove-LabVMSnapshot -SnapshotName <String> [-AllMachines] [<CommonParameters>]
```

### AllMachinesAllSnapshots
```
Remove-LabVMSnapshot [-AllMachines] [-AllSnapShots] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AllMachines
{{ Fill AllMachines Description }}

```yaml
Type: SwitchParameter
Parameter Sets: AllMachinesSnapshotByName, AllMachinesAllSnapshots
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AllSnapShots
{{ Fill AllSnapShots Description }}

```yaml
Type: SwitchParameter
Parameter Sets: ByNameAllSnapShots, AllMachinesAllSnapshots
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: ByNameSnapshotByName, ByNameAllSnapShots
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SnapshotName
{{ Fill SnapshotName Description }}

```yaml
Type: String
Parameter Sets: ByNameSnapshotByName, AllMachinesSnapshotByName
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

### System.String[]

### System.String

### System.Management.Automation.SwitchParameter

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
