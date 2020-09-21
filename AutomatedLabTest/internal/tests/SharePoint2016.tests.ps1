Describe "[$($(Get-Lab).Name)] SharePoint2016" -Tag SharePoint2016 {
Context "Role deployment successful" {
        It "[SharePoint2016] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2016).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2016'}).Count
        }
    }
}

