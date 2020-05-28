Describe "[$($(Get-Lab).Name)] SQLServer2019" -Tag SQLServer2019 {
Context "Role deployment successful" {
        It "[SQLServer2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2019'}).Count
        }
    }
}

