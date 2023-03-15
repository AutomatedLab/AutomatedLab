Describe "[$((Get-Lab).Name)] RemoteDesktopVirtualizationHost" -Tag RemoteDesktopVirtualizationHost {
    Context "Role deployment successful" {
        It "[RemoteDesktopVirtualizationHost] Should return the correct amount of machines" {
            (Get-LabVm -Role RemoteDesktopVirtualizationHost).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'RemoteDesktopVirtualizationHost'}).Count
        }
    }
}
