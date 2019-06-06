---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Connect-Lab

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Lab2Lab (Default)
```
Connect-Lab [-SourceLab] <String> [-DestinationLab] <String> [-NetworkAdapterName <String>]
 [<CommonParameters>]
```

### Site2Site
```
Connect-Lab [-SourceLab] <String> [-DestinationIpAddress] <String> [-PreSharedKey] <String>
 [[-AddressSpace] <String[]>] [-NetworkAdapterName <String>] [<CommonParameters>]
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

### -AddressSpace
{{ Fill AddressSpace Description }}

```yaml
Type: String[]
Parameter Sets: Site2Site
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationIpAddress
{{ Fill DestinationIpAddress Description }}

```yaml
Type: String
Parameter Sets: Site2Site
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationLab
{{ Fill DestinationLab Description }}

```yaml
Type: String
Parameter Sets: Lab2Lab
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkAdapterName
{{ Fill NetworkAdapterName Description }}

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

### -PreSharedKey
{{ Fill PreSharedKey Description }}

```yaml
Type: String
Parameter Sets: Site2Site
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceLab
{{ Fill SourceLab Description }}

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
