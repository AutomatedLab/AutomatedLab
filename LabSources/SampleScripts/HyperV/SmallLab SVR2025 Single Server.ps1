<#
Small Lab
- A Single Domain Controller and Member Server
- VMs are stored on D:\VMs
- Windows Server 2025 Standard (Desktop Experience)
- Get Password from PowerShell Secrets Management vault (password name = labPassword)
#>

$labName = 'localLab'
$vmPath = 'D:\VMs'
$addressSpace = '192.168.100.0/24'
$username = 'admin'
$password = Get-Secret -Name labPassword -AsPlainText
$domainName = 'yourdomain.local'
$memory = 2GB
$operatingSystemName = 'Windows Server 2025 Standard (Desktop Experience)'
$DC1Name = 'DC1'
$DCIP = '192.168.100.10'
$DNSIP = '192.168.100.10'
$SVRName = 'SVR'
$SVRIP = '192.168.100.20'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -VmPath $vmPath -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace $addressSpace -HyperVProperties @{SwitchType = 'Internal' }

Set-LabInstallationCredential -Username $username -Password $password

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name $domainName -AdminUser $username -AdminPassword $password

#the first machine is the root domain controller. Everything in $labSources\Tools get copied to the machine's Windows folder
Add-LabMachineDefinition -Name $DC1Name -Memory $memory -Network $labName -IpAddress $DCIP `
    -DnsServer1 $DNSIP -DomainName $domainName -Roles RootDC `
    -ToolsPath $labSources\Tools -OperatingSystem $operatingSystemName

#the second just a member server. Everything in $labSources\Tools get copied to the machine's Windows folder
Add-LabMachineDefinition -Name $SVRName -Memory $memory -Network $labName -IpAddress $SVRIP `
    -DnsServer1 $DNSIP -DomainName $domainName -ToolsPath $labSources\Tools `
    -OperatingSystem $operatingSystemName

Install-Lab -Verbose

Show-LabDeploymentSummary
