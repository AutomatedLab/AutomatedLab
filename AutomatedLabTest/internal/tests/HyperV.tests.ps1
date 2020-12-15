Describe "[$($Lab.Name)] HyperV" -Tag HyperV {
    Context "Role deployment successful" {
        It "[HyperV] Should return the correct amount of machines" {
            (Get-LabVM -Role HyperV).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'HyperV' }).Count
        }
        
        foreach ($vm in (Get-LabVM -Role HyperV))
        {
            if ($Lab.DefaultVirtualizationEngine -eq 'HyperV' -and (Test-IsAdministrator))
            {
                It "[$vm] should have exposed virtualization extension" -TestCases @{vm = $vm } {
            
                    (Get-VM -Name $vm.ResourceName| Get-VMProcessor).ExposeVirtualizationExtensions | Should -Be $true
                }
            }

            if ($Lab.DefaultVirtualizationEngine -eq 'Azure')
            {
                (Get-AzVm -ResourceGroupName (Get-LabAzureDefaultResourceGroup).Name -Name $vm.ResourceName).HardwareProfile.VmSize | Should -Match '_[DE]\d+(s?)_v3|_F\d+s_v2|_M\d+[mlts]*'
            }
            
            It "[$vm] should have Hyper-V feature installed" -TestCases @{vm = $vm } {
            
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName Hyper-V -NoDisplay).Installed | Should -Be $true
            }
        }
    }
}

