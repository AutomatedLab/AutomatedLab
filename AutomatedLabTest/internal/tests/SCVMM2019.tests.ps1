Describe "[$($Lab.Name)] SCVMM2019" -Tag SCVMM2019 {
Context "Role deployment successful" {
        It "[SCVMM2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SCVMM2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SCVMM2019'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SCVMM2019))
        {
            It "[$vm] Should have SQL Server 2019 installed" -TestCases @{
                vm = $vm
            } {
                Invoke-LabCommand -ComputerName $vm -NoDisplay -PassThru -ScriptBlock {
                    $path = (Get-Content -Path C:\Server.ini -ErrorAction SilentlyContinue | Where-Object {$_ -like 'ProgramFiles*'}) -split '\s*=\s*' | Select-Object -Last 1
                    Test-Path -Path $path
                } | Should -Be $true
            }
        }
    }
}

