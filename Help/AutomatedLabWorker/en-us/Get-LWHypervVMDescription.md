---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWHypervVMDescription

## SYNOPSIS
Return the serialized notes field of a Hyper-V VM

## SYNTAX

```
Get-LWHypervVMDescription [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Return the serialized notes field of a Hyper-V VM. The Notes are used to store a bunch of
information on the status that AutomatedLab found the machine in and is serialized as XML.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervVMDescription -ComputerName POSHDC1
```

Deserializes the Notes field of the VM POSHDC1

## PARAMETERS

### -ComputerName
The VM name

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
