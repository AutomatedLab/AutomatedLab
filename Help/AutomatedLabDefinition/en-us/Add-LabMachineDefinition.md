---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Add-LabMachineDefinition
schema: 2.0.0
---

# Add-LabMachineDefinition

## SYNOPSIS
Adds a definition of a machine to the lab

## SYNTAX

### Network (Default)
```
Add-LabMachineDefinition -Name <String> [-Memory <Double>] [-MinMemory <Double>] [-MaxMemory <Double>]
 [-Processors <Int32>] [-DiskName <String[]>] [-OperatingSystem <OperatingSystem>]
 [-OperatingSystemVersion <String>] [-Network <String>] [-IpAddress <String>] [-Gateway <String>]
 [-DnsServer1 <String>] [-DnsServer2 <String>] [-IsDomainJoined] [-DefaultDomain]
 [-InstallationUserCredential <PSCredential>] [-DomainName <String>] [-Roles <Role[]>] [-UserLocale <String>]
 [-PostInstallationActivity <InstallationActivity[]>] [-PreInstallationActivity <InstallationActivity[]>]
 [-ToolsPath <String>] [-ToolsPathDestination <String>] [-VirtualizationHost <VirtualizationHost>]
 [-EnableWindowsFirewall] [-AutoLogonDomainName <String>] [-AutoLogonUserName <String>]
 [-AutoLogonPassword <String>] [-AzureProperties <Hashtable>] [-HypervProperties <Hashtable>]
 [-Notes <Hashtable>] [-PassThru] [-ResourceName <String>] [-SkipDeployment] [-AzureRoleSize <String>]
 [-TimeZone <String>] [-RhelPackage <String[]>] [-SusePackage <String[]>] [-UbuntuPackage <String[]>]
 [-SshPublicKeyPath <String>] [-SshPrivateKeyPath <String>] [-OrganizationalUnit <String>]
 [-ReferenceDisk <String>] [-KmsServerName <String>] [-KmsPort <UInt16>] [-KmsLookupDomain <String>]
 [-ActivateWindows] [-InitialDscConfigurationMofPath <String>] [-InitialDscLcmConfigurationMofPath <String>]
 [-VmGeneration <Int32>] [<CommonParameters>]
```

### NetworkAdapter
```
Add-LabMachineDefinition -Name <String> [-Memory <Double>] [-MinMemory <Double>] [-MaxMemory <Double>]
 [-Processors <Int32>] [-DiskName <String[]>] [-OperatingSystem <OperatingSystem>]
 [-OperatingSystemVersion <String>] [-NetworkAdapter <NetworkAdapter[]>] [-IsDomainJoined] [-DefaultDomain]
 [-InstallationUserCredential <PSCredential>] [-DomainName <String>] [-Roles <Role[]>] [-UserLocale <String>]
 [-PostInstallationActivity <InstallationActivity[]>] [-PreInstallationActivity <InstallationActivity[]>]
 [-ToolsPath <String>] [-ToolsPathDestination <String>] [-VirtualizationHost <VirtualizationHost>]
 [-EnableWindowsFirewall] [-AutoLogonDomainName <String>] [-AutoLogonUserName <String>]
 [-AutoLogonPassword <String>] [-AzureProperties <Hashtable>] [-HypervProperties <Hashtable>]
 [-Notes <Hashtable>] [-PassThru] [-ResourceName <String>] [-SkipDeployment] [-AzureRoleSize <String>]
 [-TimeZone <String>] [-RhelPackage <String[]>] [-SusePackage <String[]>] [-UbuntuPackage <String[]>]
 [-SshPublicKeyPath <String>] [-SshPrivateKeyPath <String>] [-OrganizationalUnit <String>]
 [-ReferenceDisk <String>] [-KmsServerName <String>] [-KmsPort <UInt16>] [-KmsLookupDomain <String>]
 [-ActivateWindows] [-InitialDscConfigurationMofPath <String>] [-InitialDscLcmConfigurationMofPath <String>]
 [-VmGeneration <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Adds a definition of a machine to the lab.
This does not create the actual machine.
It merely creates the information of how the machines should look like.

## EXAMPLES

### Example 1
```powershell
Add-MachineDefinition -Name Server1 -OperatingSystem 'Windows Server 2016 Technical Preview 5 SERVERDATACENTER' -ToolsPath 'C:\LabSources\MyLabTools1' -ToolsPathDestination 'C:\MyDistTools'
```

Adds a definition of a Hyper-V machine with the name 'Server1' with the operating system of 'Windows Server 2016 Technical Preview 5 SERVERDATACENTER'.
Machine will not be domain joined but be placed in workgroup.

If using a folder for tools folder for each machine in the lab ie C:\MyLabTools1\Server1, C:\MyLabTools1\Server2 etc, you can use 'C:\MyLabTools1\\\<machine\>' and AutomatedLab will map using the name of each machine to find the tools folder.

### Example 2
```powershell
Add-MachineDefinition -Name Server1 -OperatingSystem 'Windows Server 2008 R2 Datacenter (Full Installation)' -VirtualizationHost HyperV -Memory 1GB -MinMemory 512MB -MaxMemory 2GB -DomainName 'contoso.com'
```

Adds a definition of a Hyper-V machine with the name 'Server1' with the operating system of 'Windows Server 2008 R2 Datacenter (Full Installation)'.

Following parameters for the machine, will be auto-configured: - Processors

- IPv4 address and subnet mask
- DNS server
- Regional settings (will be set to match the host machine)
- Time zone (will be set to match the host machine)
- Userlocale  (will be set to match the host machine)
- Windows firewall is disabled
- Hyper-V switch or Azure virtual network depending on -DefaultVirtualizationEngine parameter used for New-LabDefinition or -VirtualizationEngine parameter used for this function (Add-LabMachineDefinition)

### Example 3
```powershell
Add-MachineDefinition -Name Server1 -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)' -OperatingSystemVersion 6.3.9600.17415 -VirtualizationHost HyperV -Processors 2 -Memory 2GB -IpAddress '192.168.100.5/24' -Network Network1
```

Adds a definition of a Hyper-V machine with the name 'Server1' with the operating system of 'Windows Server 2012 R2 Datacenter (Server with a GUI)' with build version of '6.3.9600.17415'.

Memory will be set to 2GB (static).

### Example 4
```powershell
Add-MachineDefinition -Name Server1 -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)' -VirtualizationHost HyperV -DefaultDomain -ProductKey 'ABCDE-ABCDE-ABCDE-ABCDE-ABCDE'
```

Adds a definition of a Hyper-V machine with the name 'Server1' with the operating system of 'Windows Server 2012 R2 Datacenter (Server with a GUI)'.

Memory will be set to 2GB (static).

## PARAMETERS

### -ActivateWindows
Attempt to activate the Windows VM online or using KMS

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

### -AutoLogonDomainName
The domain for the auto logon user

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutoLogonPassword
The password for the auto logon user

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutoLogonUserName
The user name for the auto logon user

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureProperties
The Azure properties.
Don't add them unless you know what you are doing.
Currently valid properties:  'ResourceGroupName', 'UseAllRoleSizes', 'RoleSize', 'LoadBalancerRdpPort', 'LoadBalancerWinRmHttpPort', 'LoadBalancerWinRmHttpsPort', 'SubnetName','UseByolImage'

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureRoleSize
The role size of the machine on Azure

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultDomain
The default domain for the machine

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DiskName
The disk names created by Add-LabDiskDefinition

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServer1
The first DNS server for the machine

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServer2
The second DNS server for the machine

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainName
The domain name of the machine.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableWindowsFirewall
Indicates that Windows firewall should be enabled on the machine

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

### -Gateway
The default gateway for the machine

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HypervProperties
The HyperV properties.
Currently valid properties:
- AutomaticStartAction, default Nothing, refer to Set-VM
- AutomaticStartDelay, default 0, refer to Set-VM
- AutomaticStopAction, default ShutDown, refer to Set-VM
- EnableTpm, if value is 1, true or yes, TPM will be enabled
- EnableSecureBoot, if value is on, SecureBoot will be enabled
- SecureBootTemplate, MicrosoftWindows or MicrosoftUEFICertificateAuthority

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitialDscConfigurationMofPath
Path to an initial mof (machine configuration) file. Applied at first boot.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitialDscLcmConfigurationMofPath
Path to an initial meta.mof (LCM configuration) file. Applied at first boot.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallationUserCredential
The credentials of the installation user (i.e.
the local admin)

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
The static private IP address of this machine

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsDomainJoined
Indicates that the machine should be joined to a lab domain

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

### -KmsLookupDomain
If using AD-based KMS, specify the domain to look up the KMS key

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KmsPort
If specifying a standalone KMS, specify its port

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KmsServerName
Name of a standalone KMS Server

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxMemory
Maximum dynamic memory for machine Specified in bytes and must be within range 128MB-128GB.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Memory
Startup memory for machine or, if -MinMemory or -MaxMemory is not specified, static memory for machine.
Specified in bytes and must be within range 128MB-128GB.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinMemory
Minimum dynamic memory for machine Specified in bytes and must be within range 128MB-128GB.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of machine Name must consist of characters a-z, A-Z, '-' or 0-9 and must be 1-15 in length.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Network
The lab network to connect this machine to

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkAdapter
The lab network adapter to connect this machine to

```yaml
Type: NetworkAdapter[]
Parameter Sets: NetworkAdapter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes
Notes to add to the machine

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
The lab operating system to use

```yaml
Type: OperatingSystem
Parameter Sets: (All)
Aliases: OS

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystemVersion
The operating system version

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrganizationalUnit
The organizational unit to join this VM into

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the machine definition should be passed back to the caller

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

### -PostInstallationActivity
Post installation activities as defined with Get-LabPostInstallationActivity

```yaml
Type: InstallationActivity[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreInstallationActivity
List of activities to run before the machine is installed

```yaml
Type: InstallationActivity[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Processors
Virtual processor count for machine

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReferenceDisk
Path to a difference Reference Disk to be used for this machine

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceName
Name of the resource in the resource group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RhelPackage
The RHEL packages to install

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Roles
The machine's role definitions. See `[enum]::GetValues([AutomatedLab.Roles])`
or <https://automatedlab.org/en/latest/Wiki/Roles/roles/> for more information.

```yaml
Type: Role[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipDeployment
Indicates that this machine is already deployed somewhere and should only be included in the lab.
When the lab is removed, these machines are not destroyed.

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

### -SshPrivateKeyPath
The path to your SSH private key used to connect to this VM. Only supported on PowerShell 6 and newer

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SshPublicKeyPath
The path to your SSH public key used to connect to this VM. Only supported on PowerShell 6 and newer.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SusePackage
The list of SUSE packages to install during AutoYast stage

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeZone
The machine's time zone

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToolsPath
The local tools path to be copied to the machine

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToolsPathDestination
The tools path on the destination machine

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UbuntuPackage
The list of Ubuntu packages to install during cloudinit stage

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserLocale
The locale to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualizationHost
The virtualization host to use.
It is recommended to define the default virtualization host when creating a new lab

```yaml
Type: VirtualizationHost
Parameter Sets: (All)
Aliases:
Accepted values: HyperV, Azure, VMWare

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VmGeneration

Specify VM generation on Azure and Hyper-V. Only valid if supported,
possible values are 1 and 2

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:
Accepted values: 1, 2

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### None
## NOTES

## RELATED LINKS

