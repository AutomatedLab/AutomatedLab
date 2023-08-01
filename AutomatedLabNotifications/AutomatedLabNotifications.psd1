@{
    ModuleVersion          = '1.0.0'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    CompatiblePSEditions   = 'Core', 'Desktop'

    Copyright              = '2022'

    Description            = 'This module uses pluggable providers to send various kinds of notifications for AutomatedLab'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    CLRVersion             = '4.0'

    RootModule             = 'AutomatedLabNotifications.psm1'

    GUID                   = '35afbbac-f3d2-49a1-ad6e-abb89aac4349'

    FunctionsToExport      = 'Send-ALNotification'

    CmdletsToExport        = @()

    VariablesToExport      = @()

    AliasesToExport        = @()

    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('LabNotifications' , 'IFTTT', 'Toast', 'Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
