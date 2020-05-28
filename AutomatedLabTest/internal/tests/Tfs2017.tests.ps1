Describe "[$($(Get-Lab).Name)] Tfs2017" -Tag Tfs2017 {
Context "Role deployment successful" {
        It "[Tfs2017] Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2017).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Tfs2017'}).Count
        }
    }
}

