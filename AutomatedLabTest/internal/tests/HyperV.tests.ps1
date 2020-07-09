Describe "[$($Lab.Name)] HyperV" -Tag HyperV {
    Context "Role deployment successful" {
        It "[HyperV] Should return the correct amount of machines" {
            (Get-LabVM -Role HyperV).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'HyperV' }).Count
        }
        
        foreach ($vm in (Get-LabVM -Role HyperV))
        {
            It "[$vm] should have exposed virtualization extension" -Skip:$(-not (Test-IsAdministrator)) -TestCases @{vm = $vm } {
            
                (Get-VM -Name $vm.ResourceName| Get-VMProcessor).ExposeVirtualizationExtensions | Should -Be $true
            }
            It "[$vm] should have Hyper-V feature installed" -TestCases @{vm = $vm } {
            
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName Hyper-V -NoDisplay).Installed | Should -Be $true
            }
        }
    }
}

