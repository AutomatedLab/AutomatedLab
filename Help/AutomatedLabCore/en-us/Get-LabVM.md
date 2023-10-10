---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Get-LabVM
schema: 2.0.0
---

# Get-LabVM

## SYNOPSIS
Gets a lab VM object

## SYNTAX

### ByName (Default)
```
Get-LabVM [[-ComputerName] <String[]>] [-Filter <ScriptBlock>] [-IncludeLinux] [-IsRunning]
 [-SkipConnectionInfo] [<CommonParameters>]
```

### ByRole
```
Get-LabVM -Role <Roles> [-Filter <ScriptBlock>] [-IncludeLinux] [-IsRunning] [-SkipConnectionInfo]
 [<CommonParameters>]
```

### All
```
Get-LabVM [-All] [-Filter <ScriptBlock>] [-IncludeLinux] [-IsRunning] [-SkipConnectionInfo]
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves one or more lab machine objects by Name, Role or All.
Optionally only retrieves running machines.
Tries to retrieve Azure connection info for Azure labs

## EXAMPLES

### All machines
```powershell
Get-LabVm -All
```

Retrieve all machines

Name       DomainName        Ip Address    OS
----       ----------        ----------    --
ContosoDC1 contoso.com       192.168.41.10 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)
ContosoDC2 contoso.com       192.168.41.11 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)
ChildDC1   child.contoso.com 192.168.41.20 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)
ChildDC2   child.contoso.com 192.168.41.21 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)

### Get all DCs
```powershell
Get-LabVm -Role DC
```

Retrieves all Root DCs

Name       DomainName        Ip Address    OS
----       ----------        ----------    --
ContosoDC2 contoso.com       192.168.41.11 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)
ChildDC2   child.contoso.com 192.168.41.21 Windows Server 2012 R2 Datacenter (Server with a GUI) (6.3)

## PARAMETERS

### -All
Indicates that all machines should be retrieved

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The names of the machines to retrieve

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -Filter
Scriptblock to filter VMs, think Where-Object

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeLinux
Include Linux VMs in the output

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

### -IsRunning
indicates that only running machines should be retrieved

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

### -Role
The role for which machines should be returned. See `[enum]::GetValues([AutomatedLab.Roles])`
or <https://automatedlab.org/en/latest/Wiki/Roles/roles/> for more information.

```yaml
Type: Roles
Parameter Sets: ByRole
Aliases:
Accepted values: RootDC, FirstChildDC, DC, ADDS, FileServer, WebServer, DHCP, Routing, CaRoot, CaSubordinate, SQLServer2008, SQLServer2008R2, SQLServer2012, SQLServer2014, SQLServer2016, VisualStudio2013, VisualStudio2015, SharePoint2013, SharePoint2016, Orchestrator2012, SQLServer2017, SQLServer, DSCPullServer, Office2013, Office2016, ADFS, ADFSWAP, ADFSProxy, FailoverStorage, FailoverNode, Tfs2015, Tfs2017, TfsBuildWorker, Tfs2018, HyperV, AzDevOps

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipConnectionInfo
Skip generating the Azure connection info to speed up things

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AutomatedLab.Machine
## NOTES

## RELATED LINKS

