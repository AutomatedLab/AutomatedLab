#This intro script is extending '03 Single domain-joined server.ps1'. Two additional ISOs are added to the lab which are required to install
#Visual Studio 2015 and SQL Server 2014. After the lab is installed, AutomatedLab installs Redgate Relector on the DevClient1.

New-LabDefinition -Name 'Lab1' -DefaultVirtualizationEngine HyperV

Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso
Add-LabIsoImageDefinition -Name VisualStudio2015 -Path $labSources\ISOs\en_visual_studio_enterprise_2015_with_update_3_x86_x64_dvd_8923288.iso

Add-LabVirtualNetworkDefinition -Name Lab1
Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
    'Add-LabMachineDefinition:Network' = 'Lab1'
}

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch Lab1
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
Add-LabMachineDefinition -Name DC1 -Roles RootDC -NetworkAdapter $netAdapter

$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName InstallSampleDBs.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareSqlServer -KeepFolder
Add-LabMachineDefinition -Name SQL1 -Roles SQLServer2014, Routing -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name DevClient1 -OperatingSystem 'Windows 10 Pro' -Roles VisualStudio2015

Install-Lab

Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName DevClient1

Show-LabDeploymentSummary -Detailed
