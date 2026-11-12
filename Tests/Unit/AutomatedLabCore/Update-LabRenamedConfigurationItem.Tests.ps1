Describe 'Update-LabRenamedConfigurationItem' {
    BeforeAll {
        Import-Module -Name PSFramework
        . (Join-Path $PSScriptRoot '..\..\..\AutomatedLabCore\internal\functions\Update-LabRenamedConfigurationItem.ps1')

        function Get-WarningFor
        {
            param ([string]$Module)

            # Only the warnings of the helper: Set-PSFConfig logs one of its own when it refuses a value, unless the session
            # stops at the first error
            @(Get-PSFMessage | Where-Object {
                    "$($_.Level)" -eq 'Warning' -and $_.FunctionName -eq 'Update-LabRenamedConfigurationItem' -and $_.Message -like "*$Module*"
                })
        }
    }

    BeforeEach {
        # A module name of its own keeps the items of each test apart from AutomatedLab and from each other
        $script:module = 'ALRenameTest' + [guid]::NewGuid().ToString('N')
        Set-PSFConfig -Module $script:module -Name NewName -Value '0017FB' -Initialize -Validation string -Description 'Test item' -Handler {
            if ($args[0].Length -gt 11) { throw "Invalid prefix length: $($args[0])" }
        }
        $script:parameters = @{ Module = $script:module; OldName = 'OldName'; NewName = 'NewName'; DefaultValue = '0017FB' }
    }

    It 'uses the value set under the old name while the new name has its default, and says how to register it' {
        Set-PSFConfig -Module $script:module -Name OldName -Value '0017FC'

        Update-LabRenamedConfigurationItem @script:parameters 3>$null

        Get-PSFConfigValue -FullName "$($script:module).NewName" | Should -Be '0017FC'
        $warnings = Get-WarningFor -Module $script:module
        $warnings.Count | Should -Be 1
        $warnings[0].Message | Should -BeLike '*-Name NewName*Register-PSFConfig*'
    }

    It 'keeps the value of the new name when both names have a value' {
        Set-PSFConfig -Module $script:module -Name NewName -Value 'AABBCC'
        Set-PSFConfig -Module $script:module -Name OldName -Value '0017FC'

        Update-LabRenamedConfigurationItem @script:parameters 3>$null

        Get-PSFConfigValue -FullName "$($script:module).NewName" | Should -Be 'AABBCC'
    }

    It 'changes nothing and warns about nothing when the old name has no value' {
        Update-LabRenamedConfigurationItem @script:parameters

        Get-PSFConfigValue -FullName "$($script:module).NewName" | Should -Be '0017FB'
        Get-WarningFor -Module $script:module | Should -BeNullOrEmpty
    }

    It 'keeps the default and warns when the new name refuses the old value' {
        Set-PSFConfig -Module $script:module -Name OldName -Value '0017FC0017FC'

        { Update-LabRenamedConfigurationItem @script:parameters 3>$null } | Should -Not -Throw

        Get-PSFConfigValue -FullName "$($script:module).NewName" | Should -Be '0017FB'
        (Get-WarningFor -Module $script:module).Count | Should -Be 1
    }
}
