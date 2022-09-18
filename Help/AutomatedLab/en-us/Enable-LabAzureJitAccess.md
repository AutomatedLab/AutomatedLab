---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Enable-LabAzureJitAccess
schema: 2.0.0
---

# Enable-LabAzureJitAccess

## SYNOPSIS

Enable Azure Just In Time access to lab VMs

## SYNTAX

```
Enable-LabAzureJitAccess [[-MaximumAccessRequestDuration] <TimeSpan>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION

Enable Azure Just In Time access to lab VMs for WinRM, WinRM over HTTPS and Remote Desktop

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabAzureJitAccess -MaximumAccessRequestDuration 00:30:00
```

Enable JIT access for 30 minutes

## PARAMETERS

### -MaximumAccessRequestDuration
Timespan to allow JIT access

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the ARM API result will be returned

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

