Describe "[$($Lab.Name)] FailoverStorage" -Tag FailoverStorage {
    Context "Role deployment successful" {
        It "[FailoverStorage] Should return the correct amount of machines" {
            (Get-LabVM -Role FailoverStorage).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'FailoverStorage' }).Count
        } 

        foreach ($vm in (Get-LabVM -Role FailoverStorage))
        {
            It "[$vm] should have FS-iSCSITarget-Server feature installed" -TestCases @{
                vm = $vm
            } {
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName FS-iSCSITarget-Server -NoDisplay).Installed | Should -Not -Contain $false
            }
        }
    }
}

