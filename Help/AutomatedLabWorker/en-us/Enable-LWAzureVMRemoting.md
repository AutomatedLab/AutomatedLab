---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Enable-LWAzureVMRemoting

## SYNOPSIS
Enable Windows Remote Management on an Azure VM

## SYNTAX

```
Enable-LWAzureVMRemoting [-ComputerName] <String[]> [-UseSSL] [<CommonParameters>]
```

## DESCRIPTION
Enable CredSSP on an Azure VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LWAzureVMRemoting -ComputerName (Get-LabVm) -UseSsl
```

Configure CredSSP on all lab VMs and connect via SSL

## PARAMETERS

### -ComputerName
The machine to enable remoting on

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

### -UseSSL
Indicates that SSL should be used to connect to the VM

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
