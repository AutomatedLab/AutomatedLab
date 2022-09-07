---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWAzureVmSize
schema: 2.0.0
---

# Get-LWAzureVmSize

## SYNOPSIS
Return configured size of lab VM

## SYNTAX

```
Get-LWAzureVmSize [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION
Return configured size of lab VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureVmSize -Machine (get-labvm -ComputerName DFS-DC1)
```

NumberOfCores        : 2
MemoryInMB           : 7168
Name                 : Standard_D2_v2
MaxDataDiskCount     : 8
ResourceDiskSizeInMB : 102400
OSDiskSizeInMB       : 1047552
NonMappedProperties  : {}

## PARAMETERS

### -Machine
Machines to retrieve

```yaml
Type: Machine
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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

