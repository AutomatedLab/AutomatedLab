---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Enter-LabPSSession

## SYNOPSIS
Enter a PSSession

## SYNTAX

### ByName
```
Enter-LabPSSession [-ComputerName] <String> [-DoNotUseCredSsp] [-UseLocalCredential] [<CommonParameters>]
```

### ByMachine
```
Enter-LabPSSession [-Machine] <Machine> [-DoNotUseCredSsp] [-UseLocalCredential] [<CommonParameters>]
```

## DESCRIPTION
Create and enter a new PowerShell session to a lab machine.
The default authentication method is CredSsp.
To override this, the switch parameter DoNotUseCredSsp can be used.

## EXAMPLES

### Example 1


```powershell
Get-LabVM FS1 | Enter-LabPSSession -UseLocalCredentials
```

Find the lab machine FS1 and enter a session

A PowerShell session to FS1 with local credentials

## PARAMETERS

### -ComputerName
The computer name

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalCredential
Indicates whether the machine's local user credentials should be used

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

### -Machine
The lab machine

```yaml
Type: Machine
Parameter Sets: ByMachine
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseCredSsp
Indicates that CredSSP should not be used while connecting to the machine

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
