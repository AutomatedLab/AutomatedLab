$labName = 'CRMLab1'

# Create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

# Make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.81.0/24

Set-LabInstallationCredential -Username Install -Password Somepass1

# And the domain definition with the domain admin account
Add-LabDomainDefinition -Name test1.net -AdminUser Install -AdminPassword Somepass1

# Add the SQL ISO
Add-LabIsoImageDefinition -Name SQLServer2014 -Path (Join-Path -Path $labsources -ChildPath 'ISOs\en_sql_server_2014_enterprise_edition_with_service_pack_2_x64_dvd_8962401.iso')

# The first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
$role = @()
$role += Get-LabMachineRoleDefinition -Role RootDC
$role += Get-LabMachineRoleDefinition -Role SQLServer2014 -Properties @{ Features = 'SQL,Tools' }
$role += Get-LabMachineRoleDefinition -Role WebServer
$role += Get-LabMachineRoleDefinition -Role CaRoot
Add-LabMachineDefinition -Name S1DC1 -Memory 4GB -Network $labName -IpAddress 192.168.81.10 `
    -DnsServer1 192.168.81.10 -DomainName test1.net -Roles $role `
    -ToolsPath $labSources\Tools -OperatingSystem 'Windows Server 2012 R2 Datacenter (Server with a GUI)'

Install-Lab

Install-LabSoftwarePackage -ComputerName (Get-LabVM) -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S

Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning

Show-LabDeploymentSummary -Detailed
