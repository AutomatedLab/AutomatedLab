---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabDefaultOperatingSystem

## SYNOPSIS
Set default OS

## SYNTAX

```
Set-LabDefaultOperatingSystem [-OperatingSystem] <String> [[-Version] <String>] [<CommonParameters>]
```

## DESCRIPTION
Sets the default operating system for all lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabDefaultOperatingSystem -OperatingSystem Centos7.4
```

Sets the default operating system for all lab machines to Centos7.4. Can be overruled for individual machines.

## PARAMETERS

### -OperatingSystem
The OS name

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The OS version string

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
