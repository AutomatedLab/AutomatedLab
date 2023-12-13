---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWHypervNetworkSwitchDescription
schema: 2.0.0
---

# Get-LWHypervNetworkSwitchDescription

## SYNOPSIS
Return the serialized notes field of a Hyper-V Virtual Network.

## SYNTAX

```
Get-LWHypervNetworkSwitchDescription [-NetworkSwitchName] <String> [<CommonParameters>]
```

## DESCRIPTION
Return the serialized notes field of a Hyper-V Virtual Network.
The Notes are used to store metadata which is serialized as XML.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervNetworkSwitchDescription -NetworkSwitchName 'Switch1'
```

Deserializes the Notes field of the Virtual Network 'Switch'.

## PARAMETERS

### -NetworkSwitchName
The name of the Virtual Switch.

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
