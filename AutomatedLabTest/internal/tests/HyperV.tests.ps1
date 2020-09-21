Describe "[$($(Get-Lab).Name)] HyperV" -Tag HyperV {
    Context "Role deployment successful" {
        It "[HyperV] Should return the correct amount of machines" {
            (Get-LabVm -Role HyperV).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'HyperV'}).Count
        }

        
        It "[$(Get-LabVm -Role HyperV)] should have exposed virtualization extension" -Skip:$(-not (Test-IsAdministrator)) {
            foreach ($vm in (Get-LabVm -Role HyperV))
            {
                (Get-Vm -Name $vm.ResourceName | Get-VMProcessor).ExposeVirtualizationExtensions | Should -Be $true
            }
        }

        It "[$(Get-LabVm -Role HyperV)] should have Hyper-V feature installed" {
            foreach ($vm in (Get-LabVm -Role HyperV))
            {
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName Hyper-V -NoDisplay).Installed | Should -Be $true
            }
        }
    }
}

