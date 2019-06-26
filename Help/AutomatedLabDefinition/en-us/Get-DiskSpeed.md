---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-DiskSpeed

## SYNOPSIS
Measures the disk speed of the specified logical drive letter

## SYNTAX

```
Get-DiskSpeed [-DriveLetter] <String> [[-Interations] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Measures the disk speed of the specified logical drive letter.
This is used by AutomatedLab when determining optimal placement of harddisk files of Hyper-V virtual machines.

This requires the tool WinSAT which is part of the module deployment. As such, this cmdlet only works on Windows.

## EXAMPLES

### Example 1
```powershell
Get-DiskSpeed -DriveLetter C
```

Measure disk speed of drive C

### Example 2


```powershell
Get-DiskSpeed -DriveLetter D: -Iterations 5
```

Measure disk speed of drive D using 5 iterations (repetetive measurements) and return average measurement

## PARAMETERS

### -DriveLetter
Drive letter to measure

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

### -Interations
Number of measurements to perform

```yaml
Type: Int32
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
