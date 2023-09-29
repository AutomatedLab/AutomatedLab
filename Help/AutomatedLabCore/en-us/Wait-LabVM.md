---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Wait-LabVM
schema: 2.0.0
---

# Wait-LabVM

## SYNOPSIS
Wait for VM

## SYNTAX

```
Wait-LabVM [-ComputerName] <String[]> [-TimeoutInMinutes <Double>] [-PostDelaySeconds <Int32>]
 [-ProgressIndicator <Int32>] [-DoNotUseCredSsp] [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Waits for a lab machine to accept incoming sessions, indicating that it is ready to be used

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LabVM -ComputerName DC01; Invoke-LabCommand DC01 {42}
```

Wait for DC01 to be accessible before continuing with the lab

## PARAMETERS

### -ComputerName
The host to wait for

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

### -DoNotUseCredSsp
Indicates that CredSSP should not be used

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

### -NoNewLine
Indicates that no line break should be printed to the console

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

### -PostDelaySeconds
The post-wait delay

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

### -ProgressIndicator
Every n seconds, print a .
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
The timeout to wait for in minutes

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

