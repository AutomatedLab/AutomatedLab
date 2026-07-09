---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Test-LabProxmoxConnection
schema: 2.0.0
---

# Test-LabProxmoxConnection

## SYNOPSIS

Tests the connection to a Proxmox cluster

## SYNTAX

```
Test-LabProxmoxConnection [<CommonParameters>]
```

## DESCRIPTION

Tests whether a valid connection to the Proxmox cluster exists. Automatically refreshes the connection if the authentication ticket has expired.

## EXAMPLES

### Example 1

```powershell
Test-LabProxmoxConnection
```

Tests the current Proxmox cluster connection

### Example 2

```powershell
if (Test-LabProxmoxConnection) {
    Write-Host "Connected to Proxmox cluster"
} else {
    Write-Host "Not connected to Proxmox cluster"
}
```

Checks connection status and performs conditional logic

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Boolean

## NOTES

## RELATED LINKS
