param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) TfsBuildWorker" -Tag TfsBuildWorker {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role TfsBuildWorker).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'TfsBuildWorker'}).Count
        }
    }
}
