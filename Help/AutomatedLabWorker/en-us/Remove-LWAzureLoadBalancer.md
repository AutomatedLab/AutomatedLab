---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Remove-LWAzureLoadBalancer

## SYNOPSIS
Remove an Azure load balancer

## SYNTAX

```
Remove-LWAzureLoadBalancer [<CommonParameters>]
```

## DESCRIPTION
Remove an Azure load balancer

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-LWAzureLoadBalancer 
```

Remove the Azure load balancer(s) we put in front of your lab VMs. This will disable
all communication unless you manually provide an alternative such as VPN, ExpressRoute, ...

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
