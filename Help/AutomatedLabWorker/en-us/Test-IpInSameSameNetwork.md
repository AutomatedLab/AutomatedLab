---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version: https://automatedlab.org/en/latest/AutomatedLabWorker/en-us/Test-IpInSameSameNetwork
schema: 2.0.0
---

# Test-IpInSameSameNetwork

## SYNOPSIS
Test if an IP address is in the same network as another address

## SYNTAX

```
Test-IpInSameSameNetwork [[-Ip1] <IPNetwork>] [[-Ip2] <IPNetwork>] [<CommonParameters>]
```

## DESCRIPTION
Test if IP2 is in the same network as IP1

## EXAMPLES

### Example 1
```powershell
PS C:\> Test-IpInSameSameNetwork -Ip1 192.168.2.12/23 -Ip2 192.168.2.50/28
```

Checks if both IPs are in the same network.

## PARAMETERS

### -Ip1
The reference IP.
Can be an entire network object or an IP in the CIDR notation, e.g.
192.168.2.12/24

```yaml
Type: IPNetwork
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Ip2
The difference IP.
Can be an entire network object or an IP in the CIDR notation, e.g.
192.168.2.12/24

```yaml
Type: IPNetwork
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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

