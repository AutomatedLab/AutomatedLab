---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version:
schema: 2.0.0
---

# Add-HostEntry

## SYNOPSIS
Add a entry to the hosts file

## SYNTAX

### ByString
```
Add-HostEntry -IpAddress <IPAddress> -HostName <Object> -Section <String> [<CommonParameters>]
```

### ByHostEntry
```
Add-HostEntry -InputObject <Object> -Section <String> [<CommonParameters>]
```

## DESCRIPTION
Add a entry to the hosts file

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-HostEntry -IpAddress 192.168.2.1 -HostName homerouter -Section HomeEnvironment
```

Adds the host entry for the name homerouter to the section HomeEnvironment

## PARAMETERS

### -HostName
The host name to add

```yaml
Type: Object
Parameter Sets: ByString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Piped input object

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
The ip address to add to the host entry

```yaml
Type: IPAddress
Parameter Sets: ByString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Section
The section to store the entry in

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
