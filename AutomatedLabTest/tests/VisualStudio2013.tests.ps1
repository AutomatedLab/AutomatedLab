Describe "[$($Lab.Name)] VisualStudio2013" -Tag VisualStudio2013 {
Context "Role deployment successful" {
        It "[VisualStudio2013] Should return the correct amount of machines" {
            (Get-LabVm -Role VisualStudio2013).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'VisualStudio2013'}).Count
        }
    }
}

