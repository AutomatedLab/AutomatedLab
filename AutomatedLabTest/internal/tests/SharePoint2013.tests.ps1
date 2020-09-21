Describe "[$($(Get-Lab).Name)] SharePoint2013" -Tag SharePoint2013 {
Context "Role deployment successful" {
        It "[SharePoint2013] Should return the correct amount of machines" {
            (Get-LabVm -Role SharePoint2013).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SharePoint2013'}).Count
        }
    }
}

