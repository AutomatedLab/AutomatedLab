---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Remove-LabVirtualNetworkDefinition

## SYNOPSIS
Remove a virtual network definition

## SYNTAX

```
Remove-LabVirtualNetworkDefinition [-Name] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Removes a virtual network definition from the lab's network definitions

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LabVirtualNetworkDefinition -Name 'Lab01
```

Remove the network definition Lab01

## PARAMETERS

### -Name
The name of the virtual network

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
