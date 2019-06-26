---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version:
schema: 2.0.0
---

# Clear-HostFile

## SYNOPSIS
Clear a section in the hosts file

## SYNTAX

```
Clear-HostFile [-Section] <String> [<CommonParameters>]
```

## DESCRIPTION
Clear a section in the hosts file, thereby removing all contained entries

## EXAMPLES

### Example 1
```powershell
PS C:\> Clear-HostFile -Section HomeEnvironment
```

Remove the section HomeEnvironment

## PARAMETERS

### -Section
The section to remove

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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
