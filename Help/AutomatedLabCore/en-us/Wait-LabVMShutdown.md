---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Wait-LabVMShutdown
schema: 2.0.0
---

# Wait-LabVMShutdown

## SYNOPSIS
Wait for machine shutdown

## SYNTAX

```
Wait-LabVMShutdown [-ComputerName] <String[]> [-TimeoutInMinutes <Double>] [-ProgressIndicator <Int32>]
 [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Waits for one or more lab machines to shut down

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LabVMShutdown -ComputerName Host1 -TimeoutInMinutes 5
```

Wait for 5 minutes for Host1 to shut down.

## PARAMETERS

### -ComputerName
The machine names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NoNewLine
Do not add a line break to the console output

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressIndicator
After n seconds, print a .
to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutInMinutes
The shutdown timeout in minutes

```yaml
Type: Double
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

