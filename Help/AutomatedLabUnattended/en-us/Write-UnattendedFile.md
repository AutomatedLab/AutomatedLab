---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version:
schema: 2.0.0
---

# Write-UnattendedFile

## SYNOPSIS
Create files on the destination system

## SYNTAX

### Kickstart
```
Write-UnattendedFile -Content <String> -DestinationPath <String> [-Append] [-IsKickstart] [<CommonParameters>]
```

### Yast
```
Write-UnattendedFile -Content <String> -DestinationPath <String> [-Append] [-IsAutoYast] [<CommonParameters>]
```

### CloudInit
```
Write-UnattendedFile -Content <String> -DestinationPath <String> [-Append] [-IsCloudInit] [<CommonParameters>]
```

## DESCRIPTION
Create files on the destination system

## EXAMPLES

### Example 1
```powershell
PS C:\> Write-UnattendedFile -Content '@reboot root realm join contoso.com' -Path '/etc/cron.d/realmjoin'
```

Join contoso.com at reboot

## PARAMETERS

### -Append
Append an existing file, if supported

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

### -Content
File content

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

### -DestinationPath
Destination path on target system

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

### -IsAutoYast
Indicates an unattended install using AutoYAST

```yaml
Type: SwitchParameter
Parameter Sets: Yast
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsCloudInit
Indicates an unattended install using cloudinit

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
Indicates an unattended install using kickstart

```yaml
Type: SwitchParameter
Parameter Sets: Kickstart
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
