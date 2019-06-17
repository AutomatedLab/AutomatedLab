---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Enable-LWAzureWinRm

## SYNOPSIS
Enable CredSSP and WinRM

## SYNTAX

```
Enable-LWAzureWinRm [-Machine] <Machine[]> [-PassThru] [-Wait] [<CommonParameters>]
```

## DESCRIPTION
Enable CredSSP and WinRM on an Azure VM using Invoke-AzVMRunCommand

## EXAMPLES

### Example 1
```powershell
PS C:\> $jobs = Enable-LWAzureWinRm -Machine (Get-LabVm) -PassThru
PS C:\> Wait-LWLabJob $jobs
```

Enable WinRM and CredSSP on all lab machines and return the job objects.
Uses Wait-LWLabJob to wait for all jobs to finish.

## PARAMETERS

### -Machine
The machines to enable remoting on

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that jobs should be returned

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

### -Wait
Indicates that the cmdlet should wait for all jobs to finish

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
