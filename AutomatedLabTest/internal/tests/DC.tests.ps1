param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) DC" -Tag DC {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role DC).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'DC'}).Count
        }
    }
}
