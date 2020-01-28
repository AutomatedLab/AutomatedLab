---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Wait-LabADReady

## SYNOPSIS
Wait for the lab AD

## SYNTAX

```
Wait-LabADReady [-ComputerName] <String[]> [[-TimeoutInMinutes] <Int32>] [[-ProgressIndicator] <Int32>]
 [-NoNewLine] [<CommonParameters>]
```

## DESCRIPTION
Waits for the lab Active Directory to be ready by waiting for the Active Directory Web Services and executing Get-ADDomainController

## EXAMPLES

### Example 1
```powershell
PS C:\> Wait-LabADReady -ComputerName DC01
```

Wait for the Active Directory Web Services to respond on DC01

## PARAMETERS

### -ComputerName
The machine names the test will be executed on

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

### -TimeoutInMinutes
The timeout in minutes how long we should wait

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

### -ProgressIndicator
Every n seconds, print a . to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoNewLine
Indicates that no new line should be present in the output

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
