---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Request-LabAzureJitAccess
schema: 2.0.0
---

# Request-LabAzureJitAccess

## SYNOPSIS
Request JIT access for a given time span

## SYNTAX

```
Request-LabAzureJitAccess [[-ComputerName] <String[]>] [[-Duration] <TimeSpan>] [<CommonParameters>]
```

## DESCRIPTION
Request JIT access for a given time span

## EXAMPLES

### Example 1
```powershell
PS C:\> Request-LabAzureJitAccess -Duration 00:10:00
```

Request JIT access to all VMs for 10 minutes

## PARAMETERS

### -ComputerName
The computers to enable JIT for. Default: All

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Duration
The duration to enable JIT for

```yaml
Type: TimeSpan
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

