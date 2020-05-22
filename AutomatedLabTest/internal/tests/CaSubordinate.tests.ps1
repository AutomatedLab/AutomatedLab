param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) CaSubordinate" -Tag CaSubordinate {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role CaSubordinate).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'CaSubordinate'}).Count
        }
    }
}
