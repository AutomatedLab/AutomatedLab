---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# New-LWAzureLoadBalancer

## SYNOPSIS
Creates a new load balancer for the lab environment

## SYNTAX

```
New-LWAzureLoadBalancer [[-ConnectedMachines] <Machine[]>] [-PassThru] [-Wait]
```

## DESCRIPTION
Creates a new load balancer for the lab environment. Reserves a public IP for the lab
and creates the necessary frontend and backend address pools.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LWAzureLoadBalancer -PassThru
```

Creates a new Azure load balancer and returns the created object

## PARAMETERS

### -ConnectedMachines
Optionally specify which machines are connected to the load balancer

```yaml
Type: Machine[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that objects should be returned

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

### -Wait
Indicates that the cmdlet should wait for the creation of the load balancer

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

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
