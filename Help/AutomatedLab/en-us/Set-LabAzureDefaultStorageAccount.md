---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Set-LabAzureDefaultStorageAccount

## SYNOPSIS
Set default storage account

## SYNTAX

```
Set-LabAzureDefaultStorageAccount [-Name] <String> [<CommonParameters>]
```

## DESCRIPTION
Sets the default storage account for the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabAzureDefaultStorageAccount -Name labstor
```

Set the default storage account for the current lab. Usually only used by Add-LabAzureSubscription

## PARAMETERS

### -Name
The storage account name

```yaml
Type: String
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
