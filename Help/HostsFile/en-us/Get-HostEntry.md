---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version:
schema: 2.0.0
---

# Get-HostEntry

## SYNOPSIS
Retreive a host entry by host name or IP

## SYNTAX

### ByHostName
```
Get-HostEntry [-HostName <String>] [-Section <String>] [<CommonParameters>]
```

### ByIpAddress
```
Get-HostEntry [-IpAddress <IPAddress>] [-Section <String>] [<CommonParameters>]
```

## DESCRIPTION
Retreive a host entry by host name or IP

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-HostEntry -IpAddress 8.8.8.8
```

Returns the host file entry that points to 8.8.8.8

### Example 2
```powershell
PS C:\> Get-HostEntry -HostName dsctfs01
```

Returns the host file entry that points to dsctfs01

## PARAMETERS

### -HostName
The host name to look up

```yaml
Type: String
Parameter Sets: ByHostName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
The IP address to look up

```yaml
Type: IPAddress
Parameter Sets: ByIpAddress
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Section
The section to search in

```yaml
Type: String
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
