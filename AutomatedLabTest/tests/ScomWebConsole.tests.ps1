Describe "[$($Lab.Name)] ScomWebConsole" -Tag ScomWebConsole {
    Context "Role deployment successful" {
            It "[ScomWebConsole] Should return the correct amount of machines" {
                (Get-LabVm -Role ScomWebConsole).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'ScomWebConsole'}).Count
            }
            
            foreach ($vm in (Get-LabVM -Role ScomWebConsole))
            {
                It "[$vm] Should have SCOM web console installed" -TestCases @{
                    vm = $vm
                } {
                    Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                        (Get-Package -Name 'System Center Operations Manager Web Console' -Provider msi -ErrorAction SilentlyContinue).Name
                    } | Should -Be 'System Center Operations Manager Web Console'
                }
            }
        }
    }
    
    