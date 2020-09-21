Describe "[$($(Get-Lab).Name)] SQLServer2017" -Tag SQLServer2017 {
Context "Role deployment successful" {
        It "[SQLServer2017] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2017).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2017'}).Count
        }
    }
}

