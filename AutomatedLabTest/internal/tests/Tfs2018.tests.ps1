Describe "[$($(Get-Lab).Name)] Tfs2018" -Tag Tfs2018 {
Context "Role deployment successful" {
        It "[Tfs2018] Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2018).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Tfs2018'}).Count
        }
    }
}

