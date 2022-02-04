@{
    RootModule             = 'AutomatedLabTest.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '16580260-aab3-4f4c-a7ca-75cd310e4f0b'

    Author                 = 'Raimund Andree, Per Pedersen', 'Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'The module is for testing AutomatedLab'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    CLRVersion             = '4.0'

    FormatsToProcess       = @('xml\AutomatedLabTest.format.ps1xml')

    FunctionsToExport      = @(
        'Test-LabDeployment',
        'Import-LabTestResult',
        'Invoke-LabPester',
        'New-LabPesterTest'
    )

    FileList               = @('xml\AutomatedLabTest.format.ps1xml', 'AutomatedLabTest.psm1', 'AutomatedLabTest.psd1')

    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('LabTest', 'Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }

    RequiredModules        = @(
        @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0'; }
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.1.59' }
    )
}
