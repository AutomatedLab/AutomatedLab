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


Add-LabIsoImageDefinition -Name SharePoint2016 -Path $labsources\ISOs\en_sharepoint_server_2016_x64_dvd_8419458.iso

Add-LabMachineDefinition -Name SPDC1 -Memory 2gB -Roles RootDC -IpAddress 192.168.30.10
Add-LabMachineDefinition -Name SPSP1 -Memory 8gB -Roles SharePoint2016 -IpAddress 192.168.30.52

Install-Lab
