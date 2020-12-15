Describe "[$($Lab.Name)] ADFS" -Tag ADFS {
Context "Role deployment successful" {
        It "[ADFS] Should return the correct amount of machines" {
            (Get-LabVm -Role ADFS).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ADFS'}).Count
        }
    }
}

