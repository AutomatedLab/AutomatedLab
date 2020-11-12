@{
    RootModule             = 'AutomatedLabDefinition.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = 'e85df8ec-4ce6-4ecc-9720-1d08e14f27ad'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2019'

    Description            = 'The module creates the lab and machine definition for the AutomatedLab module saved in XML'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    ModuleList             = @('AutomatedLabDefinition')

    NestedModules          = @('AutomatedLabDefinitionNetwork.psm1', 'AutomatedLabDefinitionAzureServices.psm1')

    FileList               = @('AutomatedLabDefinition.psm1', 'AutomatedLabDefinition.init.ps1', 'AutomatedLabDefinitionNetwork.psm1', 'AutomatedLabDefinitionAzureServices.psm1')

    RequiredModules        = @(
        'AutomatedLabUnattended'
        'PSLog'
        'PSFramework'
    )

    CmdletsToExport        = @()

    FunctionsToExport      = @(
        'Add-LabAzureWebAppDefinition'
        'Add-LabAzureAppServicePlanDefinition'
        'Add-LabDiskDefinition'
        'Add-LabDomainDefinition'
        'Add-LabIsoImageDefinition'
        'Add-LabMachineDefinition'
        'Add-LabVirtualNetworkDefinition'
        'Export-LabDefinition'
        'Get-LabAzureWebAppDefinition'
        'Get-LabAzureAppServicePlanDefinition'
        'Get-DiskSpeed'
        'Get-LabAvailableAddresseSpace'
        'Get-LabDefinition'
        'Get-LabDomainDefinition'
        'Get-LabIsoImageDefinition'
        'Get-LabMachineDefinition'
        'Get-LabMachineRoleDefinition'
        'Get-LabPostInstallationActivity'
        'Get-LabVirtualNetwork'
        'Get-LabVirtualNetworkDefinition'
        'Get-LabVolumesOnPhysicalDisks'
        'New-LabDefinition'
        'New-LabNetworkAdapterDefinition'
        'Remove-LabDomainDefinition'
        'Remove-LabIsoImageDefinition'
        'Remove-LabMachineDefinition'
        'Remove-LabVirtualNetworkDefinition'
        'Repair-LabDuplicateIpAddresses'
        'Set-LabDefinition'
        'Set-LabLocalVirtualMachineDiskAuto'
        'Test-LabDefinition'
    )
}
