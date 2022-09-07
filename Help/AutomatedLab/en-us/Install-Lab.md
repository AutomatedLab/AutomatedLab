---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Install-Lab
schema: 2.0.0
---

# Install-Lab

## SYNOPSIS
Starts the process of lab deployment

## SYNTAX

```
Install-Lab [-NetworkSwitches] [-BaseImages] [-VMs] [-Domains] [-AdTrusts] [-DHCP] [-Routing]
 [-PostInstallations] [-SQLServers] [-Orchestrator2012] [-WebServers] [-SharepointServer] [-CA] [-ADFS]
 [-DSCPullServer] [-VisualStudio] [-Office2013] [-Office2016] [-AzureServices] [-TeamFoundation]
 [-FailoverStorage] [-FailoverCluster] [-FileServer] [-HyperV] [-WindowsAdminCenter] [-Scvmm] [-Scom]
 [-Dynamics] [-RemoteDesktop] [-ConfigurationManager] [-StartRemainingMachines] [-CreateCheckPoints]
 [-InstallRdsCertificates] [-InstallSshKnownHosts] [-PostDeploymentTests] [-NoValidation]
 [[-DelayBetweenComputers] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
If called without any parameters, Install-Lab will:
        - Create all necessary base (parent) disks for all operating systems to be used in the lab
        - Create all virtual networks to be used in the lab
        - Create all machines to be used in the lab
        - Deploy and configure all machines defined in the lab in following order:
            Root DCs
            Routing
            DHCP Servers
            First child DCs
            Additional DCs
            Create AD trusts
            Certificate (CA) servers
            SQL servers 2008/2008R2/2012/2014
            Web servers
            Orchestrator servers 2012
            Exchange servers 2013
            Sharepoint servers 2013
            Visual Studio
            Office 2013
            Start any machines without any AutomatedLab roles

If called with parameters, only the action(s) specified by the parameters will be performed.

## EXAMPLES

### Example 1
```powershell
Install-Lab
```

Deploy and configure all machines defined in the lab in following order:
            Root DCs
            Routing
            DHCP Servers
            First child DCs
            Additional DCs
            Create AD trusts
            Certificate (CA) servers
            SQL servers 2008/2008R2/2012/2014
            Web servers
            Orchestrator servers 2012
            Exchange servers 2013
            Sharepoint servers
            Visual Studio
            Office 2013
            Start any machines without any AutomatedLab roles

### Example 2
```powershell
Install-Lab -BaseImages
```

Creates all needed base images if these are not already present.
Size and/or integrity is NOT checked/verified.
If the base image (disk) exists, it will considered good.

### Example 3
```powershell
Install-Lab -BaseImages -NetworkSwitches -VMs
```

Creates all needed base images if these are not already present.
Size and/or integrity is NOT checked/verified.
If the base image (disk) exists, it will considered good.
All virtual network to be used in lab will be created.

### Example 4
```powershell
Install-Lab -BaseImages -NetworkSwitches -VMs -NoValidation
```

Same as first example but lab will be attempted validated/checked for common configuration errors.
Not recommended.
Use only if experiencing issues.

### Example 5
```powershell
Install-Lab -Domains -CA -SQLServers -WebServers -DelayBetweenComputers 30
```

Deployment/configuration of all domain controllers, all Certificate (CA) servers, SQL servers and Web servers will be performed.
There will be a deplay of 30 seconds start of each machine if more than one machine is required to start at the same time.
Use to avoid disk congestion (spread the 'load').

### Example 6
```powershell
Install-Lab -StartRemainingMachines -PostInstallations
```

Remaining machines (typically those without any AutomatedLab role), will be started and checked for readiness before contiuing.

None

## PARAMETERS

### -ADFS
Install all ADFS components

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdTrusts
Start configuring of AD trusts between all AD forests in the lab

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureServices
Deploy only Azure services

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseImages
Create base images (parent disks)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CA
Start installation of all Certificate (CA) servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationManager
Deploy ConfigMgr

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

### -CreateCheckPoints
Create checkpoints between each AutomatedLab role.
Ie Checkpoint between AD and CA and SQL etc

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DelayBetweenComputers
Seconds to wait between starting each lab machine

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DHCP
Start installation of DHCP servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domains
Start installation of Root DCs, First Child DCs and additional DCs.
Note that lab machines with Routing role (if any), will be installed between Root DCs and First Child DCs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DSCPullServer
Install all DSC Pull Servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Dynamics
Deploy Dynamics 365

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

### -FailoverCluster
Deploy only Failover Clusters

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FailoverStorage
Deploy ISCSI targets

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

### -FileServer
Deploy File Servers

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

### -HyperV
Deploy Hyper-V VMs

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

### -InstallRdsCertificates
Install certificates of virtual machines

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

### -InstallSshKnownHosts
Add lab VMs to SSH known hosts file

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

### -NetworkSwitches
Create virtual networks

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoValidation
Disable validation of the lab configuration (and thereby missing out on avoiding common configuration errors)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Office2013
Start installation of Office 2013 on all lab machines with this defined

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Office2016
Install all Office 2016 Servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Orchestrator2012
Start installation of all Orchestrator 2012 servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostDeploymentTests
Run post-deployment tests using Pester

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

### -PostInstallations
Start all post insallations of machines with this defined

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteDesktop
Deploy Remote Desktop Services

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

### -Routing
Start installation of machines with Routing role

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scom
Deploy SCOM

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

### -Scvmm
Deploy SCVMM

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

### -SharepointServer
Start installation of all Sharepoint servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: Sharepoint2013

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SQLServers
Start installation of all SQL servers.
SQL servers will be installed in batches of 4.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartRemainingMachines
Start all remaining machines which are not already started

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TeamFoundation
Deploy only CI/CD servers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VisualStudio
Start installation of Visual Studio on all lab machines with this defined

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VMs
Create lab machines

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WebServers
WebServers

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WindowsAdminCenter
Deploy Windows Admin Center

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

## NOTES

## RELATED LINKS

