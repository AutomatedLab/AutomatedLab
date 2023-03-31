Describe "[$($Lab.Name)] DC" -Tag DC {
Context "Role deployment successful" {
        It "[DC] Should return the correct amount of machines" {
            (Get-LabVm -Role DC).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DC'}).Count
        }
    }
}
