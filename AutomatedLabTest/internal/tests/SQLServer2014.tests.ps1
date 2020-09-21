Describe "[$($(Get-Lab).Name)] SQLServer2014" -Tag SQLServer2014 {
Context "Role deployment successful" {
        It "[SQLServer2014] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2014).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2014'}).Count
        }
    }
}

