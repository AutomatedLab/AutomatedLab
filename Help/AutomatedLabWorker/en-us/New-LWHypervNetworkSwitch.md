---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWHypervNetworkSwitch

## SYNOPSIS
Create a new Hyper-V switch

## SYNTAX

```
New-LWHypervNetworkSwitch [-VirtualNetwork] <VirtualNetwork[]> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Create a new Hyper-V switch

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWHypervNetworkSwitch -VirtualNetwork (Get-LabVirtualNetworkDefinition) -PassThru
```

Create all requested lab VSwitches

## PARAMETERS

### -PassThru
Indicates that the virtual switches should be returned on completion

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualNetwork
The networks to deploy

```yaml
Type: VirtualNetwork[]
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
