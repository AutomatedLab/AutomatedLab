Describe "[$($(Get-Lab).Name)] CaSubordinate" -Tag CaSubordinate {
Context "Role deployment successful" {
        It "[CaSubordinate] Should return the correct amount of machines" {
            (Get-LabVm -Role CaSubordinate).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'CaSubordinate'}).Count
        }
    }
}

