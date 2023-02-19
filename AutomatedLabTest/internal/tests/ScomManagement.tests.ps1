Describe "[$($Lab.Name)] ScomManagement" -Tag ScomManagement {
Context "Role deployment successful" {
        It "[ScomManagement] Should return the correct amount of machines" {
            (Get-LabVm -Role ScomManagement).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ScomManagement'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role ScomManagement))
        {
            It "[$vm] Should have SCOM management installed" -TestCases @{
                vm = $vm
            } {
                Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                    (Get-Package -Name 'System Center Operations Manager Server' -Provider msi -ErrorAction SilentlyContinue).Name
                } | Should -Be 'System Center Operations Manager Server'
            }
        }
    }
}

