---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Get-LWAzureVMConnectionInfo

## SYNOPSIS
Return the connection details of Azure VMs

## SYNTAX

```
Get-LWAzureVMConnectionInfo [-ComputerName] <Machine[]> [<CommonParameters>]
```

## DESCRIPTION
Return the connection details of Azure VMs. Returns the following properties:  
|Name|Purpose|
|---|---|
|ComputerName      | Host name|
|DnsName           | The Azure DNS Name (of the load balancer)|
|HttpsName         | The Azure DNS Name (of the load balancer)|
|VIP               | The public IP address (of the load balancer)|
|Port              | The load balanced WinRM port|
|HttpsPort         | The load balanced WinRM over HTTPS port|
|RdpPort           | The load balanced RDP port|
|ResourceGroupName | The resource group name|

## EXAMPLES

### Example 1
```powershell
PS C:\> $details = Get-LWAzureVMConnectionInfo DC01
PS C:\> mstsc /v "$($details.DnsName):$($details.RdpPort)"
```

Returns all necessary details to connect to DC01 and uses Remote Desktop to connect.

## PARAMETERS

### -ComputerName
The host to retrieve information from

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
