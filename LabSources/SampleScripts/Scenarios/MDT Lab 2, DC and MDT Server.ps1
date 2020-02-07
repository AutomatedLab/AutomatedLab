New-LabDefinition -Name MDTLab2 -DefaultVirtualizationEngine HyperV

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath' = "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory' = 2GB
}

$mdtRole = Get-LabPostInstallationActivity -CustomRole MDT -Properties @{
    DeploymentFolder = 'D:\DeploymentShare'
    DeploymentShare = 'DeploymentShare$'
    InstallUserID = 'MdtService'
    InstallPassword = 'Somepass1'
    OperatingSystems = 'Windows Server 2012 R2 Datacenter (Server with a GUI)', 'Windows Server 2016 Datacenter (Desktop Experience)', 'Windows Server Standard'
    AdkDownloadPath = "$labSources\SoftwarePackages\ADK"
    AdkDownloadUrl = 'https://download.microsoft.com/download/B/E/6/BE63E3A5-5D1C-43E7-9875-DFA2B301EC70/adk/adksetup.exe'
    AdkWinPeDownloadUrl = 'https://download.microsoft.com/download/E/F/A/EFA17CF0-7140-4E92-AC0A-D89366EBD79E/adkwinpeaddons/adkwinpesetup.exe'
    AdkWinPeDownloadPath = "$labSources\SoftwarePackages\ADKWinPEAddons"
    MdtDownloadUrl = 'https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi'
}

Add-LabDiskDefinition -Name MDT2Data -DiskSizeInGb 60 -Label 'MDT Data' -DriveLetter D
Add-LabMachineDefinition -Name MDT2Server -PostInstallationActivity $mdtRole -DiskName MDT2Data
Add-LabMachineDefinition -Name MDT2DC -Roles RootDC -DomainName contoso.com

Install-Lab

Show-LabDeploymentSummary -Detailed
