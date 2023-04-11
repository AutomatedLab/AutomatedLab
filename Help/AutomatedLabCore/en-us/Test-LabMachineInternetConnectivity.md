---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Test-LabMachineInternetConnectivity
schema: 2.0.0
---

# Test-LabMachineInternetConnectivity

## SYNOPSIS
Check internet connection

## SYNTAX

```
Test-LabMachineInternetConnectivity [-ComputerName] <String> [[-Count] <Int32>] [-AsJob] [<CommonParameters>]
```

## DESCRIPTION
Tests if the specified lab machine has a working internet connection

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-LabMachineInternetConnectivity -ComputerName ROUTER
```

Test if the lab VM called Router can connect to the internet
by means of sending ICMP packages.

## PARAMETERS

### -AsJob
Indicates that the cmdlet should run in the background

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

### -ComputerName
The machine name

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

### -Count
Count of connection tests

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

### System.Boolean
## NOTES

## RELATED LINKS

