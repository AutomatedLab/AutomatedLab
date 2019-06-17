---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Import-UnattendedContent

## SYNOPSIS
Import the XML or config content of the various unattend files

## SYNTAX

```
Import-UnattendedContent [-Content] <String[]> [-IsKickstart] [-IsAutoYast] [<CommonParameters>]
```

## DESCRIPTION
Import the XML or config content of the various unattend files

## EXAMPLES

### Example 1
```powershell
PS C:\> Import-UnattendedContent -Content $Machine.UnattendedContent -IsAutoYast
```

Imports the AutoYAST XML content from the machine's UnattendedContent property

## PARAMETERS

### -Content
The content to import. Either XML or plain text.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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
