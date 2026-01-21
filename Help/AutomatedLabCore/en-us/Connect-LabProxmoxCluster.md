---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Connect-LabProxmoxCluster
schema: 2.0.0
---

# Connect-LabProxmoxCluster

## SYNOPSIS

Connects to a Proxmox cluster

## SYNTAX

### NewConnection

```
Connect-LabProxmoxCluster -HostName <String> -Port <Int32> -Credential <PSCredential> [<CommonParameters>]
```

### UseExistingConnection

```
Connect-LabProxmoxCluster [-RefreshExistingConnection] [<CommonParameters>]
```

## DESCRIPTION

Establishes or refreshes a connection to a Proxmox cluster. Stores connection information for subsequent operations.

## EXAMPLES

### Example 1

```powershell
$cred = Get-Credential
Connect-LabProxmoxCluster -HostName proxmox.contoso.com -Port 8006 -Credential $cred
```

Connects to a Proxmox cluster with credentials

### Example 2

```powershell
Connect-LabProxmoxCluster -RefreshExistingConnection
```

Refreshes an existing connection to the Proxmox cluster

## PARAMETERS

### -HostName

The hostname or IP address of the Proxmox cluster

```yaml
Type: String
Parameter Sets: NewConnection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port

The port number for the Proxmox API (typically 8006)

```yaml
Type: Int32
Parameter Sets: NewConnection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credentials to use for authentication

```yaml
Type: PSCredential
Parameter Sets: NewConnection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshExistingConnection

Refreshes the connection using stored connection information

```yaml
Type: SwitchParameter
Parameter Sets: UseExistingConnection
Aliases:

Required: False
Position: Named
Default value: False
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
