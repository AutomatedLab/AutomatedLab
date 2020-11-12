Describe "[$($Lab.Name)] Tfs2018" -Tag Tfs2018 {
Context "Role deployment successful" {
        It "[Tfs2018] Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2018).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Tfs2018'}).Count
        }

        foreach ($vm in (Get-LabVM -Role Tfs2018))
        {
            $role = $vm.Roles | Where-Object Name -eq Tfs2018            
            if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
            {
                continue
            }

            It "[$vm] Should have working Tfs2018 Environment" -TestCases @{ 
                vm        = $vm
            } {
                $test = Test-LabTfsEnvironment -ComputerName $vm -NoDisplay -SkipWorker
                $test.ServerDeploymentOk | Should -Be $true
            }
        }
    }
}

