Describe "[$($Lab.Name)] ScomConsole" -Tag ScomConsole {
    Context "Role deployment successful" {
            It "[ScomConsole] Should return the correct amount of machines" {
                (Get-LabVm -Role ScomConsole).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ScomConsole'}).Count
            }
            
            foreach ($vm in (Get-LabVM -Role ScomConsole))
            {
                It "[$vm] Should have SCOM console installed" -TestCases @{
                    vm = $vm
                } {
                    Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                        (Get-Package -Name 'System Center Operations Manager Console' -Provider msi -ErrorAction SilentlyContinue).Name
                    } | Should -Be 'System Center Operations Manager Console'
                }
            }
        }
    }
    
    