---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Initialize-LWAzureVM

## SYNOPSIS
Initialize new Azure VM

## SYNTAX

```
Initialize-LWAzureVM [-Machine] <Machine[]> [<CommonParameters>]
```

## DESCRIPTION
Sets power plan, mounts the lab sources share and sets the regional settings.

## EXAMPLES

### Example 1
```powershell
PS C:\> Initialize-LWAzureVM -Machine AZDC01
```

Sets power plan, mounts the lab sources share and sets the regional settings on AZDC01.

## PARAMETERS

### -Machine
The host to configure

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
