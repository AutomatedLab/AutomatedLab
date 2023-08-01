Describe "[$($Lab.Name)] ADFSWAP" -Tag ADFSWAP {
Context "Role deployment successful" {
        It "[ADFSWAP] Should return the correct amount of machines" {
            (Get-LabVm -Role ADFSWAP).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ADFSWAP'}).Count
        }
    }
}

