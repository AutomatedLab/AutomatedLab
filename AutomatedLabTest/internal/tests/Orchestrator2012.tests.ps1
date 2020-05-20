param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) Orchestrator2012" -Tag Orchestrator2012 {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role Orchestrator2012).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'Orchestrator2012'}).Count
        }
    }
}
