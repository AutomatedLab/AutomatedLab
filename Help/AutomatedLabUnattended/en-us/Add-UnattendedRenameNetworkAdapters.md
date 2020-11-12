---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Add-UnattendedRenameNetworkAdapters

## SYNOPSIS
Add script to rename network adapters. Windows only.

## SYNTAX

```
Add-UnattendedRenameNetworkAdapters [-IsKickstart] [-IsAutoYast] [<CommonParameters>]
```

## DESCRIPTION
Add script to rename network adapters. Windows only.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-UnattendedRenameNetworkAdapters
```

Adds a script to rename network adapters

## PARAMETERS

### -IsAutoYast
Indicates that this setting is placed in an AutoYAST file

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

### -IsKickstart
Indicates that this setting is placed in a Kickstart file

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
