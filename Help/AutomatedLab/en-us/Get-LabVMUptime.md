---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabVMUptime

## SYNOPSIS
Get uptime

## SYNTAX

```
Get-LabVMUptime [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Gets the VMs uptime by checking the last boot time remotely via WMI

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabVMUptime -ComputerName FS1
```

Get the uptime of FS1

## PARAMETERS

### -ComputerName
The computer names

```yaml
Type: String[]
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
