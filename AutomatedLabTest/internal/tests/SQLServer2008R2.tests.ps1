Describe "[$($(Get-Lab).Name)] SQLServer2008R2" -Tag SQLServer2008R2 {
Context "Role deployment successful" {
        It "[SQLServer2008R2] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2008R2).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2008R2'}).Count
        }
    }
}

