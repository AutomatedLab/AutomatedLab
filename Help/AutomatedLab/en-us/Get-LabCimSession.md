---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabCimSession
schema: 2.0.0
---

# Get-LabCimSession

## SYNOPSIS
Cmdlet to list all or specific CIM sessions

## SYNTAX

```
Get-LabCimSession [[-ComputerName] <String[]>] [-DoNotUseCredSsp] [<CommonParameters>]
```

## DESCRIPTION
Cmdlet to list all or specific CIM sessions

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabCimSession
```

List all currently open CIM sessions in your lab

## PARAMETERS

### -ComputerName
List of computers to connect to

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Microsoft.Management.Infrastructure.CimSession
## NOTES

## RELATED LINKS

