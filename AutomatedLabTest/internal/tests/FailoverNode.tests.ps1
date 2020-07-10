Describe "[$($(Get-Lab).Name)] FailoverNode" -Tag FailoverNode {
Context "Role deployment successful" {
        It "[FailoverNode] Should return the correct amount of machines" {
            (Get-LabVm -Role FailoverNode).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'FailoverNode'}).Count
        }
    }
}

