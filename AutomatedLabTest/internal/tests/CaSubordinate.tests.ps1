param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) CaSubordinate" -Tag CaSubordinate {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role CaSubordinate).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'CaSubordinate'}).Count
        }
    }
}
