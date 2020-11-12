Describe "[$($Lab.Name)] Office2013" -Tag Office2013 {
Context "Role deployment successful" {
        It "[Office2013] Should return the correct amount of machines" {
            (Get-LabVm -Role Office2013).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Office2013'}).Count
        }
    }
}

