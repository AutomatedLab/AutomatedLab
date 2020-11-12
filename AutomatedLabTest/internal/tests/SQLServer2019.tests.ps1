Describe "[$($Lab.Name)] SQLServer2019" -Tag SQLServer2019 {
Context "Role deployment successful" {
        It "[SQLServer2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2019'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SQLServer2019))
        {
            It "[$vm] Should have SQL Server 2019 installed" -TestCases @{
                vm = $vm
            } {
                Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                    Test-Path -Path 'C:\Program Files\Microsoft SQL Server\150'
                } | Should -Be $true
            }

            It "[$vm] Instance(s) should be running" -TestCases @{
                vm = $vm
            } {
                $query = 'Select State from Win32_Service where Name like "MSSQLSERVER%" and StartMode = "Auto"'
                $session = New-LabCimSession -Computername $vm
                (Get-CimInstance -Query $query -CimSession $session).State | Should -Not -Contain 'Stopped'
            }
        }
    }
}

