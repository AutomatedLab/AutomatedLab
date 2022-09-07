---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Remove-LWAzureRecoveryServicesVault
schema: 2.0.0
---

# Remove-LWAzureRecoveryServicesVault

## SYNOPSIS
Remove recovery services vault in lab resource group

## SYNTAX

```
Remove-LWAzureRecoveryServicesVault [[-RetryCount] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Remove recovery services vault in lab resource group. Some users had
issues with policy deployments from their place of work which enabled
Azure Recovery Services.
AutomatedLab cannot remove the resource group if Recovery Services are
present.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWAzureRecoveryServicesVault
```

Remove the ARS Vault in the lab resource group if present

## PARAMETERS

### -RetryCount
How often do we try this

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
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

