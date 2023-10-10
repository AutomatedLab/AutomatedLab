---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedComputerName
schema: 2.0.0
---

# Set-UnattendedComputerName

## SYNOPSIS
Set the host name

## SYNTAX

### Windows (Default)
```
Set-UnattendedComputerName -ComputerName <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedComputerName -ComputerName <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedComputerName -ComputerName <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedComputerName -ComputerName <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Set the host name

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedComputerName -ComputerName Erebor
```

Sets the host name to Erebor

## PARAMETERS

### -ComputerName
The host name to set

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

