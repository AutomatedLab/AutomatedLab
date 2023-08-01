---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Get-LabAzureLabSourcesStorage
schema: 2.0.0
---

# Get-LabAzureLabSourcesStorage

## SYNOPSIS
Get Azure storage data

## SYNTAX

```
Get-LabAzureLabSourcesStorage [<CommonParameters>]
```

## DESCRIPTION
Gets the ResourceGroupName, StorageAccountName, StorageAccountKey and Path of the lab sources file storage.
To be able to use the cmdlet, you need to Add-LabAzureSubscription before.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabAzureLabSourcesStorage
```

Gets the ResourceGroupName, StorageAccountName, StorageAccountKey and Path of the lab sources file storage.
There should be one for each used subscription.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

