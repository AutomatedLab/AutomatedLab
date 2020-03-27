@{
    ModuleVersion          = '1.0.0'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    CompatiblePSEditions   = 'Core', 'Desktop'

    Copyright              = '2019'

    Description            = 'The module creates a Hyper-V visual lab automatically as defined in the XML files.'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    CLRVersion             = '4.0'

    RootModule             = 'AutomatedLabNotifications.psm1'

    GUID                   = '35afbbac-f3d2-49a1-ad6e-abb89aac4349'

    FunctionsToExport      = 'Send-ALNotification'

    CmdletsToExport        = @()

    VariablesToExport      = @()

    AliasesToExport        = @()

    FileList               = @(
        "Public\Send-ALNotification.ps1"
    )

    PrivateData            = @{ }

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
