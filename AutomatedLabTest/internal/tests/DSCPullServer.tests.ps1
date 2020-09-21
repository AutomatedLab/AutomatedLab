Describe "[$($(Get-Lab).Name)] DSCPullServer" -Tag DSCPullServer {
Context "Role deployment successful" {
        It "[DSCPullServer] Should return the correct amount of machines" {
            (Get-LabVm -Role DSCPullServer).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DSCPullServer'}).Count
        }
    }
}

