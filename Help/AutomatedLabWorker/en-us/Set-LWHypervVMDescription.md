---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Set-LWHypervVMDescription

## SYNOPSIS
Set the Notes field of a Hyper-V VM

## SYNTAX

```
Set-LWHypervVMDescription [-Hashtable] <Hashtable> [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Set the Notes field of a Hyper-V VM to store information about the VMs status.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LWHypervVMDescription -Hashtable @{
    CreatedBy = 'JHP'
    Purpose   = 'Compute'
} -ComputerName HV01
```

Deserializes the hashtable with tags to the Notes field of the Hyper-V VM HV01

## PARAMETERS

### -ComputerName
The machine to set the notes field of

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hashtable
A hashtable containing notes. Values will be converted to String

```yaml
Type: Hashtable
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
