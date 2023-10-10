---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Export-UnattendedFile
schema: 2.0.0
---

# Export-UnattendedFile

## SYNOPSIS
Save the unattend file

## SYNTAX

### Windows (Default)
```
Export-UnattendedFile -Path <String> [<CommonParameters>]
```

### CloudInit
```
Export-UnattendedFile -Path <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Export-UnattendedFile -Path <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Export-UnattendedFile -Path <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Save the unattend file.
Creates an XML file for Windows and AutoYAST or a Kickstart (cfg) file for Kickstart.

## EXAMPLES

### Example 1
```powershell
PS C:\> Export-UnattendFile -Path .\unattend.xml
```

Exports an Unattend file for Windows

## PARAMETERS

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

### -Path
The path to the resulting file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

