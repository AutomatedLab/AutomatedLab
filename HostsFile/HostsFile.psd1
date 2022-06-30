@{
    RootModule             = 'HostsFile.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '8dc3dd5c-5ae8-4198-a8f2-2157ab6b725c'

    Author                 = 'Raimund Andree, Per Pedersen'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'This module provides management of hosts file content'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    ModuleList             = @('HostsFile')

    FunctionsToExport      = 'Add-HostEntry', 'Clear-HostFile', 'Get-HostEntry', 'Get-HostFile', 'Remove-HostEntry'

    FileList               = @('HostsFile.psm1', 'HostsFile.psd1')

    RequiredModules        = @('PSFramework')

    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('HostFile', 'HostEntry')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
