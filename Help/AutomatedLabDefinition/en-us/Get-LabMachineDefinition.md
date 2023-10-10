---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabMachineDefinition
schema: 2.0.0
---

# Get-LabMachineDefinition

## SYNOPSIS
Returns all machine definitions in the lab

## SYNTAX

### ByName (Default)
```
Get-LabMachineDefinition [[-ComputerName] <String[]>] [<CommonParameters>]
```

### ByRole
```
Get-LabMachineDefinition -Role <Roles> [<CommonParameters>]
```

### All
```
Get-LabMachineDefinition [-All] [<CommonParameters>]
```

## DESCRIPTION
Returns all machine definitions in the lab

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-LabMachineDefinition -Role WebServer
```

Get all WebServer machine definitions

## PARAMETERS

### -All
Indicates that all definitions should be returned

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The machine definitions to return

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Role
The roles to filter the machine definitions on. See `[enum]::GetValues([AutomatedLab.Roles])`
or <https://automatedlab.org/en/latest/Wiki/Roles/roles/> for more information.

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:
Accepted values: RootDC, FirstChildDC, DC, ADDS, FileServer, WebServer, DHCP, Routing, CaRoot, CaSubordinate, SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016, VisualStudio2013, VisualStudio2015, SharePoint2013, SharePoint2016, Orchestrator2012, SQLServer2017, DSCPullServer, Office2013, Office2016, ADFS, ADFSWAP, ADFSProxy, SQLServer2019, FailoverStorage, FailoverNode, Tfs2015, Tfs2017, TfsBuildWorker, Tfs2018, HyperV, AzDevOps, SharePoint2019, SharePoint, WindowsAdminCenter, Scvmm2016, Scvmm2019, ScomManagement, ScomConsole, ScomWebConsole, ScomReporting, ScomGateway, SCOM, DynamicsFull, DynamicsFrontend, DynamicsBackend, DynamicsAdmin, Dynamics, RemoteDesktopGateway, RemoteDesktopWebAccess, RemoteDesktopSessionHost, RemoteDesktopConnectionBroker, RemoteDesktopLicensing, RemoteDesktopVirtualizationHost, RDS, ConfigurationManager, Scvmm2022, SCVMM, SQLServer2022, SQLServer

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

