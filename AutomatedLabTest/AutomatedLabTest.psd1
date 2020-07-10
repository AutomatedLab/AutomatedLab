@{
    RootModule             = 'AutomatedLabTest.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '16580260-aab3-4f4c-a7ca-75cd310e4f0b'

    Author                 = 'Raimund Andree, Per Pedersen', 'Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2020'

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

    PrivateData            = @{ }

    RequiredModules        = @(
        @{ ModuleName='Pester'; ModuleVersion='5.0.0'; }
        @{ ModuleName='PSFramework'; ModuleVersion='1.1.59' }
    )
}
