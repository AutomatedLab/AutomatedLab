---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Join-LabVMDomain
schema: 2.0.0
---

# Join-LabVMDomain

## SYNOPSIS
Join a VM to a domain

## SYNTAX

```
Join-LabVMDomain [-Machine] <Machine[]> [<CommonParameters>]
```

## DESCRIPTION
Joins one or more lab VMs to their defined domain

## EXAMPLES

### Example 1
```powershell
PS C:\> Join-LabVMDomain -Machine Node1,Node2
```

Join Node1 and Node2 to their defined domains.

## PARAMETERS

### -Machine
The lab machines

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

