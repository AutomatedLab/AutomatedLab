Describe "[$($Lab.Name)] SCVMM2016" -Tag SCVMM2016 {
Context "Role deployment successful" {
        It "[SCVMM2016] Should return the correct amount of machines" {
            (Get-LabVm -Role SCVMM2016).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SCVMM2016'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SCVMM2016))
        {
            It "[$vm] Should have SCVMM 2016 installed" -TestCases @{
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

