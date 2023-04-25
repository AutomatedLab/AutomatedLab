@{
    RootModule             = 'AutomatedLabUnattended.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = 'b20c8df3-3f74-4537-a40b-b53186084dd5'

    Author                 = 'Raimund Andree, Per Pedersen'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'The module is managing settings inside an unattended.xml file'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    RequiredModules        = @( )

    FunctionsToExport      = @(
        'Add-UnattendedNetworkAdapter',
        'Add-UnattendedRenameNetworkAdapters',
        'Add-UnattendedSynchronousCommand',
        'Export-UnattendedFile',
        'Get-UnattendedContent',
        'Import-UnattendedContent',
        'Import-UnattendedFile',
        'Set-UnattendedAdministratorName',
        'Set-UnattendedAdministratorPassword',
        'Set-UnattendedAntiMalware',
        'Set-UnattendedAutoLogon',
        'Set-UnattendedComputerName',
        'Set-UnattendedDomain',
        'Set-UnattendedFirewallState',
        'Set-UnattendedIpSettings',
        'Set-UnattendedLocalIntranetSites',
        'Set-UnattendedPackage',
        'Set-UnattendedProductKey',
        'Set-UnattendedTimeZone',
        'Set-UnattendedUserLocale',
        'Set-UnattendedWorkgroup'
    )

    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('UnattendedFile', 'Kickstart', 'AutoYast', 'Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
