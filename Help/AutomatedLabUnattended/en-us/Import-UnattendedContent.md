---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Import-UnattendedContent
schema: 2.0.0
---

# Import-UnattendedContent

## SYNOPSIS
Import the XML or config content of the various unattend files

## SYNTAX

### Windows (Default)
```
Import-UnattendedContent -Content <String[]> [<CommonParameters>]
```

### CloudInit
```
Import-UnattendedContent -Content <String[]> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Import-UnattendedContent -Content <String[]> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Import-UnattendedContent -Content <String[]> [-IsKickstart] [<CommonParameters>]
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
The content to import.
Either XML or plain text.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsAutoYast
Indicates that this setting is placed in an AutoYAST file

```yaml
Type: SwitchParameter
Parameter Sets: Yast
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsCloudInit
Indicates that this setting is placed in a cloudinit file

```yaml
Type: SwitchParameter
Parameter Sets: CloudInit
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
Parameter Sets: Kickstart
Aliases:

Required: False
Position: Named
Default value: False
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

