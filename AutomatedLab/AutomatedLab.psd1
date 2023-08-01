@{
    RootModule             = 'AutomatedLab.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '6ee6d36f-7914-4bf6-9e3b-c0131669e808'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'Automated lab environments with ease - Linux and Windows, Hyper-V and Azure'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    CLRVersion             = '4.0'

    ScriptsToProcess       = @()

    FormatsToProcess       = @( )

    NestedModules          = @( )

    RequiredModules        = @(
        'AutomatedLabCore'
        @{ ModuleName = 'AutomatedLab.Common'; ModuleVersion = '2.3.17' }
        'AutomatedLab.Recipe'
        'AutomatedLab.Ships'
        'AutomatedLabDefinition'
        'AutomatedLabNotifications'
        'AutomatedLabTest'
        'AutomatedLabUnattended'
        'AutomatedLabWorker'
        'PSLog'
        'PSFileTransfer'
        'HostsFile'
        'Pester'
        'powershell-yaml'
        'PSFramework'
        'SHiPS'
    )

    CmdletsToExport        = @()

    FunctionsToExport      = @( )

    AliasesToExport        = @( )

    FileList               = @( )

    PrivateData       = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
