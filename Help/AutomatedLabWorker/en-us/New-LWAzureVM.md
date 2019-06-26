---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWAzureVM

## SYNOPSIS
Create a new Azure VM

## SYNTAX

```
New-LWAzureVM [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION
Create a new Azure VM. The VM role size is gathered from either the default role size, the configured role
size in the machine definition or by the memory and CPU consumption.

Depending on the role, a SKU will be selected. SQL Server for example is available as a separate SKU and
will be automatically selected.

This cmdlet also takes care of assigning the necessary managed disks, network adapters and is responsible
for creating the necessary inbound NAT rules for each new VM

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWAzureVM -Machine DC01
```

Creates the VM DC01

## PARAMETERS

### -Machine
The machine definition to deploy

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
