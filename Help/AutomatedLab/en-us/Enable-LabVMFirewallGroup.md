---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Enable-LabVMFirewallGroup

## SYNOPSIS
Enable firewall group on machine

## SYNTAX

```
Enable-LabVMFirewallGroup [-ComputerName] <String[]> [-FirewallGroup] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Enables one or more named firewall groups on one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabVMFirewallGroup -ComputerName WSUS1,WSUS2 -FirewallGroup 'Delivery Optimization'
```

Enable the 'Delivery Optimization' firewall group on WSUS1 and WSUS2

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

### -FirewallGroup
The firewall group names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
