Describe "[$($(Get-Lab).Name)] TfsBuildWorker" -Tag TfsBuildWorker {
Context "Role deployment successful" {
        It "[TfsBuildWorker] Should return the correct amount of machines" {
            (Get-LabVm -Role TfsBuildWorker).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'TfsBuildWorker'}).Count
        }
    }
}

