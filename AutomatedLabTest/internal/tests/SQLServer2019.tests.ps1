param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) SQLServer2019" -Tag SQLServer2019 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2019).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2019'}).Count
        }
    }
}
