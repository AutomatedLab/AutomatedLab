---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Restore-LabConnection

## SYNOPSIS

Restore the lab connection

## SYNTAX

```
Restore-LabConnection [-SourceLab] <String> [-DestinationLab] <String> [<CommonParameters>]
```

## DESCRIPTION

Restore the lab connection

## EXAMPLES

### Example 1
```powershell
PS C:\> Restore-LabConnection -Source Lab1 -Destination Lab2
```

In case of changed public IP addresses restore the lab connection

## PARAMETERS

### -SourceLab
The source lab that has been used for the first connection

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

### -DestinationLab
The destination lab that has been used

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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
