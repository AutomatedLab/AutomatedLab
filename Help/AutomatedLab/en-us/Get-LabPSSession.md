---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabPSSession

## SYNOPSIS
Get PSSessions

## SYNTAX

```
Get-LabPSSession [[-ComputerName] <String[]>] [-DoNotUseCredSsp] [<CommonParameters>]
```

## DESCRIPTION
Get all open PowerShell sessions to one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabPSSession
```

List all open lab PSSession objects

### Example 2
```powershell
PS C:\> Get-LabPSSession -ComputerName DC1
```

Gets available session to DC1

## PARAMETERS

### -ComputerName
The computer names

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

### -DoNotUseCredSsp
Indicates that CredSSP is not to be used

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

### System.Management.Automation.Runspaces.PSSession
## NOTES

## RELATED LINKS
