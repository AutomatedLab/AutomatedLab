Describe "[$($Lab.Name)] DHCP" -Tag DHCP {
Context "Role deployment successful" {
        It "[DHCP] Should return the correct amount of machines" {
            (Get-LabVm -Role DHCP).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'DHCP'}).Count
        }
    }
}

