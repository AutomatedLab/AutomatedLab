New-LabDefinition -Name 'MDTLab1' -DefaultVirtualizationEngine HyperV

$mdtRole = Get-LabPostInstallationActivity -CustomRole MDT -Properties @{
    DeploymentFolderLocation = 'C:\DeploymentShare'
    InstallUserID = 'MdtService'
    InstallPassword = 'Somepass1'
    OperatingSystems = 'Windows Server 2012 R2 Datacenter (Server with a GUI)', 'Windows Server 2016 Datacenter (Desktop Experience)', 'Windows Server Standard'
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
}

Add-LabMachineDefinition -Name MDT1Server -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -PostInstallationActivity $mdtRole

Install-Lab

Show-LabDeploymentSummary -Detailed