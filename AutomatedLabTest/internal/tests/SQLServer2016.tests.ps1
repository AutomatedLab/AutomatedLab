Describe "[$($(Get-Lab).Name)] SQLServer2016" -Tag SQLServer2016 {
Context "Role deployment successful" {
        It "[SQLServer2016] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2016).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2016'}).Count
        }
    }
}

