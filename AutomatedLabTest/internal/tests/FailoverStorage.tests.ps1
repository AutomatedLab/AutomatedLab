Describe "[$($(Get-Lab).Name)] FailoverStorage" -Tag FailoverStorage {
Context "Role deployment successful" {
        It "[FailoverStorage] Should return the correct amount of machines" {
            (Get-LabVm -Role FailoverStorage).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'FailoverStorage'}).Count
        }
    }
}

