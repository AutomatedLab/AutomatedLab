#This intro script is extending '03 Single domain-joined server.ps1'. An additional ISO is added to the lab which is required to install Visual Studio 2015.
#After the lab is installed, AutomatedLab installs Redgate Relector on the DevClient1.

New-LabDefinition -Name 'Lab1' -DefaultVirtualizationEngine HyperV

$labSources = Get-LabSourcesLocation
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch Lab1
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch Internet -UseDhcp
Add-LabMachineDefinition -Name DC1 -Roles RootDC, Routing -NetworkAdapter $netAdapter

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName InstallSampleDBs.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareSqlServer -KeepFolder
Add-LabMachineDefinition -Name SQL1 -Roles SQLServer2014 -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name DevClient1 -OperatingSystem 'Windows 10 Pro' -Roles VisualStudio2015

Install-Lab

Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName DevClient1

Show-LabInstallationTime