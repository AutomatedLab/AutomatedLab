---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWHypervVM

## SYNOPSIS
Create a new Hyper-V VM

## SYNTAX

```
New-LWHypervVM [-Machine] <Machine> [<CommonParameters>]
```

## DESCRIPTION
Create a new Hyper-V VM. Takes care of both Windows and Linux VMs.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWHypervVM -Machine Host1
```

Creates the VM Host1 with all accompanying artifacts like Disks, ...

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
