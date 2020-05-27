param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SQLServer2016" -Tag SQLServer2016 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2016).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2016'}).Count
        }
    }
}
