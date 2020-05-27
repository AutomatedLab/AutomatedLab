param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SQLServer2008R2" -Tag SQLServer2008R2 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2008R2).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2008R2'}).Count
        }
    }
}
