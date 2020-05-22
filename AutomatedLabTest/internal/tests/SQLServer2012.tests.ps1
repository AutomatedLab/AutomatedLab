param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) SQLServer2012" -Tag SQLServer2012 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2012).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2012'}).Count
        }
    }
}
