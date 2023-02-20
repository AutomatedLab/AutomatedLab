---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWAzureSku
schema: 2.0.0
---

# Get-LWAzureSku

## SYNOPSIS
Internal worker to list Azure SKUs

## SYNTAX

```
Get-LWAzureSku [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION
Internal worker to list Azure SKUs

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWAzureSku -Machine (Get-LabVm Host1)
```

Generate the SKU to use for the given machine (definition)

## PARAMETERS

### -Machine
The machine to generate the SKU for

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

