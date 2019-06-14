---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Dismount-LWAzureIsoImage

## SYNOPSIS
Unmount an ISO image on an Azure VM

## SYNTAX

```
Dismount-LWAzureIsoImage [-ComputerName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Unmount an ISO image on an Azure VM

## EXAMPLES

### Example 1
```powershell
PS C:\> Dismount-LWAzureIsoImage -ComputerName (Get-LabVm -Role AzDevOps)
```

Unmount all ISO images on all machines with the role Azure DevOps

## PARAMETERS

### -ComputerName
The machines to dismount all ISOs on

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
