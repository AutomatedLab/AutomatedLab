param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) TfsBuildWorker" -Tag TfsBuildWorker {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role TfsBuildWorker).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'TfsBuildWorker'}).Count
        }
    }
}
