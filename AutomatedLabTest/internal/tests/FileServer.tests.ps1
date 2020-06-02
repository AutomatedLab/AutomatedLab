Describe "[$($(Get-Lab).Name)] FileServer" -Tag FileServer {
Context "Role deployment successful" {
        It "[FileServer] Should return the correct amount of machines" {
            (Get-LabVm -Role FileServer).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'FileServer'}).Count
        }
    }
}

