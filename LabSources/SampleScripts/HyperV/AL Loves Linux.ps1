$labName = 'ALLovesLinux'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.130.0/24
Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DnsServer1' = '192.168.130.10'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 SERVERDATACENTER'
}
$PSDefaultParameterValues.Add('Add-LabMachineDefinition:Gateway', '192.168.130.50')

Add-LabDomainDefinition -Name contoso.com -AdminUser install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name LINDC1 -Roles RootDC -Memory 1GB -PostInstallationActivity $postInstallActivity -IpAddress 192.168.130.10 -DomainName contoso.com

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.130.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
Add-LabMachineDefinition -Name LINGW1 -Memory 1GB -Roles Routing -NetworkAdapter $netAdapter -DomainName contoso.com

# Make sure to download an ISO that contains the selected packages as well as SSSD,oddjob,oddjob-mkhomedir and adcli
# Or use an internet-connected lab so that the packages can be loaded on the fly
Add-LabMachineDefinition -RhelPackage domain-client -Name LINCN1 -OperatingSystem 'CentOS 7.4' -DomainName contoso.com
Add-LabMachineDefinition -Name LINSU1 -OperatingSystem 'openSUSE Leap 42.3' -DomainName contoso.com -Memory 2GB

# Non domain-joined
Add-LabMachineDefinition -Name LINCN2 -OperatingSystem 'CentOS 7.4'
Add-LabMachineDefinition -Name LINSU2 -OperatingSystem 'openSUSE Leap 42.3' -Memory 2GB
Install-Lab

break
Invoke-LabCommand -ComputerName LINCN1 -ScriptBlock {$PSVersionTable | Format-Table } -PassThru