Describe "[$($(Get-Lab).Name)] SharePoint2019" -Tag SharePoint2019 {
Context "Role deployment successful" {
        It "[SharePoint2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2019'}).Count
        }
    }
}

