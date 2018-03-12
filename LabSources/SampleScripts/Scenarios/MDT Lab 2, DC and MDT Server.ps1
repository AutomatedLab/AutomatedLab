New-LabDefinition -Name 'MDTLab2' -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath' = "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory' = 2GB
}

$mdtRole = Get-LabPostInstallationActivity -CustomRole MDT -Properties @{
    DeploymentFolderLocation = 'D:\DeploymentShare'
    InstallUserID = 'MdtService'
    InstallPassword = 'Somepass1'
    OperatingSystems = 'Windows Server 2012 R2 Datacenter (Server with a GUI)', 'Windows Server 2016 Datacenter (Desktop Experience)', 'Windows Server Standard'
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
}

Add-LabDiskDefinition -Name MDT2Data -DiskSizeInGb 60
Add-LabMachineDefinition -Name MDT2Server -PostInstallationActivity $mdtRole -DiskName MDT2Data
Add-LabMachineDefinition -Name MDT2DC -Roles RootDC -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed