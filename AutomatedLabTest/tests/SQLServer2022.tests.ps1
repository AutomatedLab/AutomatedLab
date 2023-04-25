Describe "[$($Lab.Name)] SQLServer2022" -Tag SQLServer2022 {
Context "Role deployment successful" {
        It "[SQLServer2022] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2022).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2022'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SQLServer2022))
        {
            It "[$vm] Should have SQL Server 2022 installed" -TestCases @{
                vm = $vm
            } {
                Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                    Test-Path -Path 'C:\Program Files\Microsoft SQL Server\160'
                } | Should -Be $true
            }

            It "[$vm] Instance(s) should be running" -TestCases @{
                vm = $vm
            } {
                $role = $vm.Roles | Where-Object Name -like SQLServer* | Sort-Object Name -Descending | Select-Object -First 1
                $roleInstance = if ($role.Properties -and $role.Properties['InstanceName'])
                {
                    $role.Properties['InstanceName']
                }
                else
                {
                    'MSSQLSERVER'
                }
                $query = 'Select State from Win32_Service where Name = "{0}" and StartMode = "Auto"' -f $roleInstance
                $session = New-LabCimSession -Computername $vm
                (Get-CimInstance -Query $query -CimSession $session).State | Should -Not -Contain 'Stopped'
            }
        }
    }
}

