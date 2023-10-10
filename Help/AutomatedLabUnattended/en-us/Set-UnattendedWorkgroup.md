---
external help file: AutomatedLabUnattended-help.xml
Module Name: AutomatedLabUnattended
online version: https://automatedlab.org/en/latest/AutomatedLabUnattended/en-us/Set-UnattendedWorkgroup
schema: 2.0.0
---

# Set-UnattendedWorkgroup

## SYNOPSIS
Configures the workgroup of a non domain-joined system

## SYNTAX

### Windows (Default)
```
Set-UnattendedWorkgroup -WorkgroupName <String> [<CommonParameters>]
```

### CloudInit
```
Set-UnattendedWorkgroup -WorkgroupName <String> [-IsCloudInit] [<CommonParameters>]
```

### Yast
```
Set-UnattendedWorkgroup -WorkgroupName <String> [-IsAutoYast] [<CommonParameters>]
```

### Kickstart
```
Set-UnattendedWorkgroup -WorkgroupName <String> [-IsKickstart] [<CommonParameters>]
```

## DESCRIPTION
Configures the workgroup of a non domain-joined system

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-UnattendedWorkgroup -WorkgroupName LocalWG
```

Joins the workgroup LocalWG

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

### -WorkgroupName
The workgroup to configure

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

