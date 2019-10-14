@{
    #Severity       = @('Error', 'Warning')
    'ExcludeRules' = @('PSUseDeclaredVarsMoreThanAssignments', 'PSAvoidGlobalVars', 'PSAvoidUsingUsernameAndPasswordParams', 'PSAvoidUsingWMICmdlet')
    'Rules'        = @{
        PSUseCompatibleCommmands = @{
            Enable = $true
            TargetProfiles = @(
                'ubuntu_x64_18.04_6.1.3_x64_4.0.30319.42000_core'
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            )
            <# You can specify commands to not check like this, which also will ignore its parameters:
            IgnoreCommands = @(
                'Install-Module'
            )#>
        }
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @(
                "6.0",
                "5.1"
            )
        }
    }
}