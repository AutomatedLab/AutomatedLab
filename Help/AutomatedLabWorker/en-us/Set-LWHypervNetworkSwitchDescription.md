---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Set-LWHypervNetworkSwitchDescription
schema: 2.0.0
---

# Set-LWHypervNetworkSwitchDescription

## SYNOPSIS
Set the Notes field of a Hyper-V VM

## SYNTAX

```
Set-LWHypervNetworkSwitchDescription [-Hashtable] <Hashtable> [-NetworkSwitchName] <String> [<CommonParameters>]
```

## DESCRIPTION
Set the Notes field of a Hyper-V Virtual Network to store meta data.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LWHypervNetworkSwitchDescription -Hashtable @{
    CreatedBy = 'JHP'
    Purpose   = 'Compute'
} -NetworkSwitchName Switch1
```

Deserializes the hashtable with tags to the Notes field of the Hyper-V Virtual Switch `Switch1`.

## PARAMETERS

### -NetworkSwitchName
The name of the network switch to set the notes field for.

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
A hashtable containing notes.
Values will be converted to String

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

