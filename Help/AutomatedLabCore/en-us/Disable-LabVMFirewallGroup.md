---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Disable-LabVMFirewallGroup
schema: 2.0.0
---

# Disable-LabVMFirewallGroup

## SYNOPSIS
Deactivate firewall group on machine

## SYNTAX

```
Disable-LabVMFirewallGroup [-ComputerName] <String[]> [-FirewallGroup] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Deactivates one or more named firewall groups on one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Disable-LabVMFirewallGroup -ComputerName Node1,Node2 -FirewallGroup 'Microsoft Store'
```

Disable the named group 'Microsoft Store' on Node1 and Node2

## PARAMETERS

### -ComputerName
The machine names

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

