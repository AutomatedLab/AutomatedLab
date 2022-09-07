---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Get-LWHypervVM
schema: 2.0.0
---

# Get-LWHypervVM

## SYNOPSIS
Get all VMs running on a Hyper-V

## SYNTAX

```
Get-LWHypervVM [[-Name] <String[]>] [[-DisableClusterCheck] <Boolean>] [-NoError] [<CommonParameters>]
```

## DESCRIPTION
Get all VMs running on a Hyper-V

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LWHypervVM -DisableClusterCheck $true
```

Get machines on a cluster node locally, bypassing the check for clustering to
speed up the cmdlet.

## PARAMETERS

### -DisableClusterCheck
Default when not in cluster, speed up the cmdlet calls by not checking
each time

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Names of the VMs to retrieve.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoError
Indicates that the cmdlet should not throw but return $null

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

