Describe "[$($Lab.Name)] Tfs2017" -Tag Tfs2017 {
Context "Role deployment successful" {
        It "[Tfs2017] Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2017).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Tfs2017'}).Count
        }

        foreach ($vm in (Get-LabVM -Role Tfs2017))
        {
            $role = $vm.Roles | Where-Object Name -eq Tfs2017            
            if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
            {
                continue
            }

            It "[$vm] Should have working Tfs2017 Environment" -TestCases @{ 
                vm        = $vm
            } {
                $test = Test-LabTfsEnvironment -ComputerName $vm -NoDisplay -SkipWorker
                $test.ServerDeploymentOk | Should -Be $true
            }
        }
    }
}

