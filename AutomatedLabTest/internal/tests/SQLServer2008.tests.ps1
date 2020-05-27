param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SQLServer2008" -Tag SQLServer2008 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2008).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2008'}).Count
        }
    }
}
