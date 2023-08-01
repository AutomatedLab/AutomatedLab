---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Register-LabAzureRequiredResourceProvider
schema: 2.0.0
---

# Register-LabAzureRequiredResourceProvider

## SYNOPSIS
Register all required Azure resource providers used by AutomatedLab

## SYNTAX

```
Register-LabAzureRequiredResourceProvider [-SubscriptionName] <String> [[-ProgressIndicator] <Int32>]
 [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Register all required Azure resource providers used by AutomatedLab

## EXAMPLES

### Example 1
```powershell
PS C:\> Register-LabAzureRequiredResourceProvider -SubscriptionName 'TheSubscription'
```

Register Compute, Network and Storage resource providers as well as the Bastion feature

## PARAMETERS

### -NoDisplay
Do not display information.

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

### -ProgressIndicator
After n seconds, print a . to the console

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubscriptionName
Name of the subscription to enable resource providers for.

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
