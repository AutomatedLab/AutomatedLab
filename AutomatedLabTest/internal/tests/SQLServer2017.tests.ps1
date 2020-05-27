param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SQLServer2017" -Tag SQLServer2017 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2017).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2017'}).Count
        }
    }
}
