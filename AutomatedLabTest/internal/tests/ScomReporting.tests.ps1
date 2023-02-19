Describe "[$($Lab.Name)] ScomReporting" -Tag ScomReporting {
    Context "Role deployment successful" {
            It "[ScomReporting] Should return the correct amount of machines" {
                (Get-LabVm -Role ScomReporting).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ScomReporting'}).Count
            }
            
            foreach ($vm in (Get-LabVM -Role ScomReporting))
            {
                It "[$vm] Should have SCOM Reporting installed" -TestCases @{
                    vm = $vm
                } {
                    Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                        (Get-Package -Name 'System Center Operations Manager Reporting Server' -Provider msi -ErrorAction SilentlyContinue).Name
                    } | Should -Be 'System Center Operations Manager Reporting Server'
                }
            }
        }
    }
    
    