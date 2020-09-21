Describe "[$($(Get-Lab).Name)] SQLServer2012" -Tag SQLServer2012 {
Context "Role deployment successful" {
        It "[SQLServer2012] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2012).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2012'}).Count
        }
    }
}

