Describe "[$($(Get-Lab).Name)] AzDevOps" -Tag AzDevOps {
Context "Role deployment successful" {
        It "[AzDevOps] Should return the correct amount of machines" {
            (Get-LabVm -Role AzDevOps).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'AzDevOps'}).Count
        }
    }
}

