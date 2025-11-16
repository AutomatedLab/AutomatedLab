Describe "[$($Lab.Name)] SCVMM2019" -Tag SCVMM2019 {
Context "Role deployment successful" {
        It "[SCVMM2019] Should return the correct amount of machines" {
            (Get-LabVm -Role SCVMM2019).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'SCVMM2019'}).Count
        }
        
        foreach ($vm in (Get-LabVM -Role SCVMM2019))
        {
            It "[$vm] Should have SCVMM 2019 installed" -TestCases @{
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

