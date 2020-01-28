---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Dismount-LabIsoImage

## SYNOPSIS
Dismounts an ISO

## SYNTAX

```
Dismount-LabIsoImage [-ComputerName] <String[]> [-SupressOutput] [<CommonParameters>]
```

## DESCRIPTION
Dismounts the mounted ISO image file from one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Dismount-LabIsoImage -ComputerName SQL01
```

Unmount all ISO files on SQL01, making room for new ones...

## PARAMETERS

### -ComputerName
The computer names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SupressOutput
Indicates whether output should be suppressed or not

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

## OUTPUTS

## NOTES

## RELATED LINKS
