@{
    RootModule             = 'PSFileTransfer.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '789c9c76-4756-4489-a74f-31ca64488c7b'

    Author                 = 'Raimund Andree, Per Pedersen'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2019'

    Description            = 'This module packages functions created by Lee Holmes for transfering files over PowerShell Remoting'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '2.0'

    ModuleList             = @('PSFileTransfer')

    FunctionsToExport      = 'Copy-LabFileItem', 'Send-Directory', 'Send-File', 'Receive-Directory', 'Receive-File'

    FileList               = @('PSFileTransfer.psm1', 'PSFileTransfer.psd1')

    RequiredModules        = @()
}
