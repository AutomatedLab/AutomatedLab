<#
.DESCRIPTION
    This test verifies, that all strings that have been used,
    are listed in the language files and thus have a message being displayed.

    It also checks, whether the language files have orphaned entries that need cleaning up.
#>

$moduleRoot = (Get-Module AutomatedLabTest).ModuleBase
$stringsResults = Export-PSMDString -ModuleRoot $moduleRoot
$exceptions = & "$PSScriptRoot\strings.Exceptions.ps1"

Describe "Testing localization strings" {
    foreach ($stringEntry in $stringsResults) {
        if ($stringEntry.String -eq "key") { continue } # Skipping the template default entry
        It "Should be used & have text: $($stringEntry.String)" {
            if ($exceptions.LegalSurplus -notcontains $stringEntry.String) {
                $stringEntry.Surplus | Should -BeFalse
            }
            $stringEntry.Text | Should -Not -BeNullOrEmpty
        }
    }
}