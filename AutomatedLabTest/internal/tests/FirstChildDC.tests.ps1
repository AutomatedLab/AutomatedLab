Describe "[$($Lab.Name)] FirstChildDC" -Tag FirstChildDC {
Context "Role deployment successful" {
        It "[FirstChildDC] Should return the correct amount of machines" {
            (Get-LabVm -Role FirstChildDC).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'FirstChildDC'}).Count
        }
    }
}

