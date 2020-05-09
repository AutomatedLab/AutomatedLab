# Active Directory

For Active Directory AutomatedLab provides three roles: RootDC, FirstChildDC and DC. AL knows about standard parameters for all roles but allows a fair amount of customization.
AL supports multi-forest and / or multi-domain environments in a single lab. AL will try to get the number of domains to add from the definition of domain controllers. AL auto-detects domains in a simple environment. If your lab is more complex, it is recommended to define the domains manually using the cmdlet Add-LabDomainDefinition.
Some more documentation on the parameters is down below.

## Root Domain Controllers (RootDC)
Each forest starts with a Root Domain Controller. The number of forests in your lab is defined by the number of machines with the role RootDC and by the domains you are assigning these machines to. Having two Root Domain Controllers in a domain results in an error.
The role RootDC supports the following parameters for customizations: SiteName, SiteSubnet, DomainFunctionalLevel and ForestFunctionalLevel.

### Role Assignment
The simple assignment that takes the default settings:
```powershell
Add-LabMachineDefinition -Name DC1 -OperatingSystem 'Windows 2016 SERVERDATACENTER' -Roles RootDC
```
The next example demonstrates the usage of all available parameters:
```powershell
$role = Get-LabMachineRoleDefinition -Role RootDC @{
    ForestFunctionalLevel = 'Win2012R2'
    DomainFunctionalLevel = 'Win2012R2'
    SiteName = 'Frankfurt'
    SiteSubnet = '192.168.10.0/24'
}
Add-LabMachineDefinition -Name T3RDC1 -IpAddress 192.168.10.10 -DomainName contoso.com -Roles $role
```
## First Child Domain Controller (FirstChildDC)
If you need a child domain or a new tree in your forest, you start with assigning this role to a machine. Like for the RootDC role AL tries to auto-detect missing data, like the root domain. If you assign a role FirstChildDC to a machine which is in the domain child.contoso.com, AL take contoso.com as the parent domain. If you are running more than one forest in a lab, this cannot work anymore and some more data is required.
This role needs to know about the name of the new child domain or domain tree and the parent domain name. If this cannot be retrieved automatically, an error is thrown.

### Role Assignment
The simple example for this role looks identical with the one for the role RootDC. The next example demonstrates all available parameters:

```powershell
$role = Get-LabMachineRoleDefinition -Role FirstChildDC @{
    ParentDomain = 'contoso.com'
    NewDomain = 'emea'
    DomainFunctionalLevel = 'Win2012R2'
    SiteName = 'London'
    SiteSubnet = '192.168.50.0/24'

}
Add-LabMachineDefinition -Name LDC1 -IpAddress 192.168.50.10 -DomainName emea.contoso.com -Roles $role
```
## Domain Controller (DC)
This role can be assigned to a machine to become an additional domain controller in a root or child domain defined earlier. You cannot have the role DC without having also the role RootDC or FirstChildDC. 
This role supports the parameters SiteName, SiteSubnet and ReadOnly

### Role Assignment
Using all these parameters looks like this:
```powershell
$role = Get-LabMachineRoleDefinition -Role DC @{
    SiteName = 'Milano'
    SiteSubnet = '192.168.60.0/24'
    IsReadOnly = 'true'
}
Add-LabMachineDefinition -Name RODC1 -IpAddress 192.168.60.10 -DomainName emea.contoso.com -Roles $role
```

## Installation Process
The installation is done when calling 'Install-Lab' without using additional parameters. To start only the Active Directory installation, you can use 'Install-Lab -Domains’.

## Requirements
This role cannot be assigned to a client OS. The only additional requirement is to provide the correct data if AL cannot discover your intended setup automatically.

## Parameters
### ForestFunctionalLevel (RootDC)
This value is only available for the RootDC role and takes the Forest Functional Level. Valid values are
- Win2008R2
- Win2012
- Win2012R2
- WinThreshold (Win2016)

### DomainFunctionalLevel (RootDC and FirstChildDC)
This value is available on the roles RootDC and FirstChildDC and controls the Domain Functional Level. Valid values are
- Win2008R2
- Win2012
- Win2012R2
- WinThreshold (Win2016)

### SiteName
When defined, AL creates the given site after promoting the domain controller and moves the domain controller into that site.

### DatabasePath
Stores the AD database files in the given folder.

### LogPath
Stores the AD log files in the given folder.

### SysvolPath
Stores the Sysvol folder in the given folder

### DsrmPassword
When defined, set the Directory Services Restore Mode password to something different than the lab's install user's password.

### SiteSubnet
When defined, AL creates a new Active Directory Replication subnet and assigns it to the site creates previously. The parameter SiteSubnet requires SiteName to be defined.

### IsReadOnly (DC)
This string parameter makes the domain controller a read-only domain controller. Use 'true' to enable the ReadOnly DC role.

### NewDomain (FirstChildDC)
Defines the new domain name for the FirstChildDC. If this value is a FQDN, AL creates a new domain tree, in case of a short name a child domain is created.

### ParentDomain (FirstChildDC)
This specifies the root domain the new domain should be located in. The parameter takes the full FQDN.
