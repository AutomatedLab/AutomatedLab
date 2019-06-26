---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version:
schema: 2.0.0
---

# Remove-HostEntry

## SYNOPSIS
Remove a host entry

## SYNTAX

### ByIpAddress
```
Remove-HostEntry -IpAddress <IPAddress> -Section <String> [<CommonParameters>]
```

### ByHostName
```
Remove-HostEntry -HostName <Object> -Section <String> [<CommonParameters>]
```

### ByHostEntry
```
Remove-HostEntry -InputObject <Object> -Section <String> [<CommonParameters>]
```

## DESCRIPTION
Remove a host entry

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-HostEntry -Ip 8.8.8.8 | Remove-HostEntry
```

Gets a host entry and uses the bound parameter InputObject to remove the entry

## PARAMETERS

### -HostName
The host name to remove

```yaml
Type: Object
Parameter Sets: ByHostName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
The host file entry to remove

```yaml
Type: Object
Parameter Sets: ByHostEntry
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
The IP address to remove

```yaml
Type: IPAddress
Parameter Sets: ByIpAddress
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Section
The section to remove in

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
