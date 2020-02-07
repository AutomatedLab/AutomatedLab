New-LabDefinition -Name MDTLab1 -DefaultVirtualizationEngine HyperV

$mdtRole = Get-LabPostInstallationActivity -CustomRole MDT -Properties @{
    DeploymentFolder = 'C:\DeploymentShare'
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

Add-LabMachineDefinition -Name MDT1Server -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -PostInstallationActivity $mdtRole

Install-Lab

Show-LabDeploymentSummary -Detailed
