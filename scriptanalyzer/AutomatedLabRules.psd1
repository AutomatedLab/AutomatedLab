@{
    #Severity       = @('Error', 'Warning')
    'ExcludeRules' = @(
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingComputerNameHardcoded',
        'PSPossibleIncorrectComparisonWithNull'
        )
    'Rules'        = @{
        PSUseCompatibleCommmands = @{
            Enable = $true
            TargetProfiles = @(
                'ubuntu_x64_18.04_6.1.3_x64_4.0.30319.42000_core',
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
            )
        }
        PSUseCompatibleCmdlets = @{
            'compatibility' = @("desktop-5.1.14393.206-windows", 'core-6.1.0-linux')
        }
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @(
                "6.0",
                "5.1"
            )
        }
    }
    CustomRulePath = '.\scriptanalyzer\ALCustomRules.psm1'
}