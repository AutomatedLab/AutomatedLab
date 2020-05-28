Describe "[$($(Get-Lab).Name)] SQLServer2008" -Tag SQLServer2008 {
Context "Role deployment successful" {
        It "[SQLServer2008] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2008).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2008'}).Count
        }
    }
}

