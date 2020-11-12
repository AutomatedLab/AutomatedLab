Describe "[$($Lab.Name)] Orchestrator2012" -Tag Orchestrator2012 {
Context "Role deployment successful" {
        It "[Orchestrator2012] Should return the correct amount of machines" {
            (Get-LabVm -Role Orchestrator2012).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Orchestrator2012'}).Count
        }
    }
}

