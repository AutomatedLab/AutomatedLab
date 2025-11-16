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
                $whichIni = if ($vm.Roles.Properties.ContainsKey('SkipServer')) {'Console.ini'} else {'Server.ini'}
                Invoke-LabCommand -ComputerName $vm -NoDisplay -Variable (Get-Variable whichIni, AL_DeployDebugFolder) -PassThru -ScriptBlock {
                    $deployDebug =  (Get-Item -Path $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder)).FullName
                    $path = (Get-Content -Path (Join-Path $deployDebug $whichIni) -ErrorAction SilentlyContinue | Where-Object {$_ -like 'ProgramFiles*'}) -split '\s*=\s*' | Select-Object -Last 1
                    Test-Path -Path $path
                } | Should -Be $true
            }
        }
    }
}

