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
Add-UnattendedRenameNetworkAdapters [-IsKickstart] [-IsAutoYast]
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

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
