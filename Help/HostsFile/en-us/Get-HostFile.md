---
external help file: HostsFile-help.xml
Module Name: HostsFile
online version: https://automatedlab.org/en/latest/HostsFile/en-us/Get-HostFile
schema: 2.0.0
---

# Get-HostFile

## SYNOPSIS
Get host file content

## SYNTAX

```
Get-HostFile [-SuppressOutput] [[-Section] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get host file content

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-HostFile -Section Lab1
```

Get host entries for Lab1

## PARAMETERS

### -Section
Section to look in, typically name of your lab.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SuppressOutput
Suppress additional output

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

