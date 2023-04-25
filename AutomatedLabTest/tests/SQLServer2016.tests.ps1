Describe "[$($Lab.Name)] SQLServer2016" -Tag SQLServer2016 {
Context "Role deployment successful" {
        It "[SQLServer2016] Should return the correct amount of machines" {
            (Get-LabVm -Role SQLServer2016).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SQLServer2016'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SQLServer2016))
        {
            It "[$vm] Should have SQL Server 2016 installed" -TestCases @{
                vm = $vm
            } {
                Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                    Test-Path -Path 'C:\Program Files\Microsoft SQL Server\130'
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

