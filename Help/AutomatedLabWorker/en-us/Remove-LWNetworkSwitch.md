---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Remove-LWNetworkSwitch

## SYNOPSIS
Remove a Hyper-V network switch

## SYNTAX

```
Remove-LWNetworkSwitch [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Remove a Hyper-V network switch

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWNetworkSwitch -Name LabNetwork
```

Remove the virtual switch LabNetwork

## PARAMETERS

### -Name
The name of the switch to remove.

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
