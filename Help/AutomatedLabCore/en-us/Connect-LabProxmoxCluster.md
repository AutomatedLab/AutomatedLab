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

### CredentialConnection (Default)

```
Connect-LabProxmoxCluster -HostName <String> -Port <Int32> -Credential <PSCredential> [<CommonParameters>]
```

### TokenConnection

```
Connect-LabProxmoxCluster -HostName <String> -Port <Int32> -ApiToken <String> [<CommonParameters>]
```

### UseExistingConnection

```
Connect-LabProxmoxCluster [-RefreshExistingConnection] [<CommonParameters>]
```

## DESCRIPTION

Establishes or refreshes a connection to a Proxmox cluster. Stores connection information for subsequent operations.

Two authentication methods are supported:

- **Credential-based authentication** using a `PSCredential` object (user name and password).
- **API token authentication** using a Proxmox API token in the format `USER@REALM!TOKENID=UUID`. API tokens can be created in the Proxmox web UI under *Datacenter -> Permissions -> API Tokens* and are recommended for unattended automation because they can be scoped and revoked without changing the user's password.

## EXAMPLES

### Example 1

```powershell
$cred = Get-Credential
Connect-LabProxmoxCluster -HostName proxmox.contoso.com -Port 8006 -Credential $cred
```

Connects to a Proxmox cluster with credentials.

### Example 2

```powershell
Connect-LabProxmoxCluster -HostName proxmox.contoso.com -Port 8006 -ApiToken 'automation@pve!lab=8a4d2f9c-1b3e-4f7a-9d2c-6f0e5b8a1c23'
```

Connects to a Proxmox cluster using an API token. The token must be in the format `USER@REALM!TOKENID=UUID`.

### Example 3

```powershell
Connect-LabProxmoxCluster -RefreshExistingConnection
```

Refreshes an existing connection to the Proxmox cluster using the previously supplied credentials or API token.

## PARAMETERS

### -HostName

The hostname or IP address of the Proxmox cluster

```yaml
Type: String
Parameter Sets: CredentialConnection, TokenConnection
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
Parameter Sets: CredentialConnection, TokenConnection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

The credentials to use for authentication. Mutually exclusive with `-ApiToken`.

```yaml
Type: PSCredential
Parameter Sets: CredentialConnection
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

A Proxmox API token used for authentication. Must be in the format `USER@REALM!TOKENID=UUID`
(for example `automation@pve!lab=8a4d2f9c-1b3e-4f7a-9d2c-6f0e5b8a1c23`). Mutually exclusive with `-Credential`.

```yaml
Type: String
Parameter Sets: TokenConnection
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
