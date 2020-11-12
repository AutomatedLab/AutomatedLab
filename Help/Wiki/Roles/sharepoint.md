# SharePoint Server

The roles SharePoint2013, SharePoint2016 and SharePoint2019 install all required binaries for SharePoint. Currently, no farm or content is deployed.
All preqrequisites are downloaded automatically, but can be prepared easily in an offline scenario.

In order to really deploy SharePoint according to your needs, consider using [SharePointDsc](https://github.com/dsccommunity/SharePointDsc) with ```Invoke-LabDscConfiguration```.

## Example

The following example would install all three supported versions of SharePoint:

```powershell
$labName = 'SharingIsCaring'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.30.10'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}


Add-LabIsoImageDefinition -Name SharePoint2013 -Path $labsources\ISOs\en_sharepoint_server_2013_with_sp1_x64_dvd_3823428.iso
Add-LabIsoImageDefinition -Name SharePoint2016 -Path $labsources\ISOs\en_sharepoint_server_2016_x64_dvd_8419458.iso
Add-LabIsoImageDefinition -Name SharePoint2019 -Path $labsources\ISOs\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso

Add-LabMachineDefinition -Name SPDC1 -Memory 2gB -Roles RootDC -IpAddress 192.168.30.10
Add-LabMachineDefinition -Name SPSP1 -Memory 4gB -Roles SharePoint2013 -IpAddress 192.168.30.13 -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'
Add-LabMachineDefinition -Name SPSP2 -Memory 4gB -Roles SharePoint2016 -IpAddress 192.168.30.16
Add-LabMachineDefinition -Name SPSP3 -Memory 4gB -Roles SharePoint2019 -IpAddress 192.168.30.19

Install-Lab
```

## Prerequisites

We store a list of prerequisites with PSFramework, which means that you can customize this setting or use it to download
and prepare the prerequisites! To do that, you can find a list of URIs with ```Get-LabConfigurationItem SharePoint2016Prerequisites # Adjust to your version```.

Simply store the downloaded files without renaming them in ```$labsources\SoftwarePackages\SharePoint2016 # Adjust to your version```. All files are picked up automatically even when no connection is available.