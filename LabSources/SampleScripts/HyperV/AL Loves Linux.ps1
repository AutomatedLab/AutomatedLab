$labName = 'ALLovesLinux'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.130.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DnsServer1' = '192.168.130.10'
    'Add-LabMachineDefinition:Memory' = 1.5GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter'
}
$PSDefaultParameterValues.Add('Add-LabMachineDefinition:Gateway', '192.168.130.10')

Add-LabDomainDefinition -Name contoso.com -AdminUser install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.130.10
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name LINDC1 -Roles RootDC, Routing -Memory 1GB -PostInstallationActivity $postInstallActivity -NetworkAdapter $netAdapter -DomainName contoso.com

# Make sure to download an ISO that contains the selected packages as well as SSSD,oddjob,oddjob-mkhomedir and adcli
# Or use an internet-connected lab so that the packages can be loaded on the fly
Add-LabMachineDefinition -Name LINCN1 -OperatingSystem 'CentOS-7' -DomainName contoso.com -RhelPackage gnome-desktop
Add-LabMachineDefinition -Name LINSU1 -OperatingSystem 'openSUSE Leap 15.1' -DomainName contoso.com -SusePackage gnome_basis

# Non domain-joined
Add-LabMachineDefinition -Name LINCN2 -OperatingSystem 'CentOS-7' -RhelPackage gnome-desktop
Add-LabMachineDefinition -Name LINSU2 -OperatingSystem 'openSUSE Leap 15.1' -SusePackage gnome_basis
Install-Lab

break
Invoke-LabCommand -ComputerName LINCN1 -ScriptBlock {$PSVersionTable | Format-Table } -PassThru