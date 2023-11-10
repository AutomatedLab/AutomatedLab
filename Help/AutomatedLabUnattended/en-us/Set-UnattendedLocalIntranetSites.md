---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedLocalIntranetSites
schema: 2.0.0
---

# Set-UnattendedLocalIntranetSites

## SYNOPSIS
Set the local intranet sites.
Windows only.

## SYNTAX

### Windows (Default)
```
Set-UnattendedLocalIntranetSites -Values <String[]> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedLocalIntranetSites -Values <String[]> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedLocalIntranetSites -Values <String[]> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedLocalIntranetSites -Values <String[]> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the local intranet sites. Windows only.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedLocalIntranetSites -Values https://definitly.not.malicious,http://lobtool
```

Adds two URLs to the local intranet sites

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

### -Values
The list of URLs to add

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

