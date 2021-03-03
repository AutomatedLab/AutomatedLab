# HyperV - SmallLab 2012R2 SQL

INSERT TEXT HERE

```powershell
$labName = 'SmallSQL'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.80.0/24

#read all ISOs in the LabSources folder and add the SQL 2014 ISO
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso

Set-LabInstallationCredential -Username Install -Password Somepass1

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name test1.net -AdminUser Install -AdminPassword Somepass1

#the first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
Add-LabMachineDefinition -Name S2DC1 -Memory 512MB -Network $labName -DomainName test1.net -Roles RootDC `
    -ToolsPath $labSources\Tools -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

#the second the SQL 2014 Server with the role assigned
Add-LabMachineDefinition -Name S2Sql1 -Memory 1GB -Network $labName -DomainName test1.net -Roles SQLServer2014 `
    -ToolsPath $labSources\Tools -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

Install-Lab
```
