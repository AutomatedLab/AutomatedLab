---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWHypervVMSnapshot

## SYNOPSIS
Find snapshots of Hyper-V VMs

## SYNTAX

```
Get-LWHypervVMSnapshot [-VMName] <String[]> [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Find snapshots of Hyper-V VMs

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervVMSnapshot -VMName DSCDC01
```

List all existing snapshots of DSCDC01

## PARAMETERS

### -Name
Snapshot name to look for

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VMName
VM to get snapshots from

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
