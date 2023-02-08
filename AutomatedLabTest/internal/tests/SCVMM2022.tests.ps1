Describe "[$($Lab.Name)] SCVMM2022" -Tag SCVMM2022 {
Context "Role deployment successful" {
        It "[SCVMM2022] Should return the correct amount of machines" {
            (Get-LabVm -Role SCVMM2022).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SCVMM2022'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SCVMM2022))
        {
            It "[$vm] Should have SCVMM 2022 installed" -TestCases @{
                vm = $vm
            } {
                $whichIni = if ($vm.Roles.Properties.ContainsKey('SkipServer')) {'c:\Console.ini'} else {'C:\Server.ini'}
                Invoke-LabCommand -ComputerName $vm -NoDisplay -Variable (Get-Variable whichIni) -PassThru -ScriptBlock {
                    $path = (Get-Content -Path $whichIni -ErrorAction SilentlyContinue | Where-Object {$_ -like 'ProgramFiles*'}) -split '\s*=\s*' | Select-Object -Last 1
                    Test-Path -Path $path
                } | Should -Be $true
            }
        }
    }
}

