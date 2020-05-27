param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) SQLServer2014" -Tag SQLServer2014 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2014).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'SQLServer2014'}).Count
        }
    }
}
