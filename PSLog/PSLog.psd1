@{
    RootModule             = 'PSLog.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = 'cd303a6c-f405-4dcb-b1ce-fbc2c52264e9'

    Author                 = 'Raimund Andree, Per Pedersen'

    Description            = 'Redirects stanard Write-* cmdlets to a log and offers some basic tracing functions'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '3.5'

    RequiredModules        = @( )

    FunctionsToExport      = @(
        'Get-CallerPreference',
        'Write-LogError',
        'Write-LogFunctionEntry',
        'Write-LogFunctionExit',
        'Write-LogFunctionExitWithError',
        'Write-ProgressIndicator',
        'Write-ProgressIndicatorEnd',
        'Write-ScreenInfo'
    )

    PrivateData            = @{
        AutoStart      = $true
        DefaultFolder  = ''
        DefaultName    = 'PSLog'
        Level          = 'All'
        Silent         = $false
        TruncateTypes  = @(
            'System.Management.Automation.ScriptBlock'
        )
        TruncateLength = 50

        PSData         = @{
            Prerelease   = ''
            Tags         = @('Logging')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
