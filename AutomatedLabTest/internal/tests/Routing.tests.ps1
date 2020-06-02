Describe "[$($(Get-Lab).Name)] Routing" -Tag Routing {
Context "Role deployment successful" {
        It "[Routing] Should return the correct amount of machines" {
            (Get-LabVm -Role Routing).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Routing'}).Count
        }
    }
}

