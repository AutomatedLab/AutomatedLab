---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version:
schema: 2.0.0
---

# Add-HostEntry

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -HostName
{{ Fill HostName Description }}

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
{{ Fill InputObject Description }}

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
{{ Fill IpAddress Description }}

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
{{ Fill Section Description }}

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
