---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Stop-LabVM

## SYNOPSIS
Stop a machine

## SYNTAX

### ByName
```
Stop-LabVM [-ComputerName] <String[]> [-ShutdownTimeoutInMinutes <Double>] [-Wait] [-ProgressIndicator <Int32>]
 [-NoNewLine] [-KeepAzureVmProvisioned] [<CommonParameters>]
```

### All
```
Stop-LabVM [-ShutdownTimeoutInMinutes <Double>] [-All] [-Wait] [-ProgressIndicator <Int32>] [-NoNewLine]
 [-KeepAzureVmProvisioned] [<CommonParameters>]
```

## DESCRIPTION
Stops one or more lab machines

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-LabVm -All -Wait -KeepAzureVmProvisioned
```

Shutdown all lab VMs but keep Azure resources provisioned, incurring costs.

## PARAMETERS

### -ComputerName
The computer names

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShutdownTimeoutInMinutes
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

### -Wait
Indicates that we should wait for the machine to stop

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

### -ProgressIndicator
Every n seconds, print a . to the console

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

### -NoNewLine
Indicates that no new lines should be present in the output

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

### -All
Indicates that all lab machines should be stopped

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepAzureVmProvisioned
Indicates that an Azure VM should not be deallocated

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
