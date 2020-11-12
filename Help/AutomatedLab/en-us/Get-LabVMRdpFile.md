---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMRdpFile

## SYNOPSIS
Get RDP connection file

## SYNTAX

### ByName
```
Get-LabVMRdpFile -ComputerName <String[]> [-UseLocalCredential] [<CommonParameters>]
```

### All
```
Get-LabVMRdpFile [-UseLocalCredential] [-All] [<CommonParameters>]
```

## DESCRIPTION
Gets a Remote Desktop connection file for one or more lab machines and stores the files in the LabLocation, e.g.
%ProgramData%\AutomatedLab\Labs\\\<LabName\>\

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMRdpFile -ComputerName DC01
```

Stores an RDP connection file to DC01

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
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalCredential
Indicates whether the machines' local credentials should be used to connect

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

### -All
Create RDP files for all lab VMs

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
