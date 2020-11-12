Describe "[$($Lab.Name)] ADFSProxy" -Tag ADFSProxy {
Context "Role deployment successful" {
        It "[ADFSProxy] Should return the correct amount of machines" {
            (Get-LabVm -Role ADFSProxy).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ADFSProxy'}).Count
        }
    }
}

