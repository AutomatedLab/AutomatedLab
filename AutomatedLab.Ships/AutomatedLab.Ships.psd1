﻿@{
    RootModule             = 'AutomatedLab.Ships.psm1'
    CompatiblePSEditions   = 'Core', 'Desktop'
    ModuleVersion          = '1.0.0'
    GUID                   = 'fc08e0e1-d274-41a3-afdd-09247e497c08'
    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'
    CompanyName            = 'AutomatedLab Team'
    Description            = 'The SHiPS module to mount a lab drive containing all lab data'
    PowerShellVersion      = '5.1'
    DotNetFrameworkVersion = '4.0'
    CLRVersion             = '4.0'
    RequiredModules        = @( )
    FileList               = @('AutomatedLab.Ships.psm1', 'AutomatedLab.Ships.psd1')

    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('ShipsProvider', 'Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
