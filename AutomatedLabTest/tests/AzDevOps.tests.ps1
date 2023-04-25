Describe "[$($Lab.Name)] AzDevOps" -Tag AzDevOps {
Context "Role deployment successful" {
        It "[AzDevOps] Should return the correct amount of machines" {
            (Get-LabVm -Role AzDevOps).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'AzDevOps'}).Count
        }

        foreach ($vm in (Get-LabVM -Role AzDevOps))
        {
            $role = $vm.Roles | Where-Object Name -eq AzDevOps            
            if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
            {
                continue
            }

            It "[$vm] Should have working AzDevOps Environment" -TestCases @{ 
                vm        = $vm
            } {
                $test = Test-LabTfsEnvironment -ComputerName $vm -NoDisplay -SkipWorker
                $test.ServerDeploymentOk | Should -Be $true
            }
        }
    }
}

