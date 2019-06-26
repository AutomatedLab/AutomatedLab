---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Repair-LWHypervNetworkConfig

## SYNOPSIS
Reorder and rename Hyper-V VM network adapters

## SYNTAX

```
Repair-LWHypervNetworkConfig [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Reorder and rename Hyper-V VM network adapters. The status of the repair will be
added to the notes field of the VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Repair-LWHypervNetworkConfig -ComputerName Router01
```

Reorders and renames all NICs of Router01

## PARAMETERS

### -ComputerName
Host name to repair

```yaml
Type: String
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
