Describe "[$($Lab.Name)] Tfs2015" -Tag Tfs2015 {
Context "Role deployment successful" {
        It "[Tfs2015] Should return the correct amount of machines" {
            (Get-LabVm -Role Tfs2015).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Tfs2015'}).Count
        }

        foreach ($vm in (Get-LabVM -Role Tfs2015))
        {
            $role = $vm.Roles | Where-Object Name -eq Tfs2015            
            if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
            {
                continue
            }

            It "[$vm] Should have working Tfs2015 Environment" -TestCases @{ 
                vm        = $vm
            } {
                $test = Test-LabTfsEnvironment -ComputerName $vm -NoDisplay -SkipWorker
                $test.ServerDeploymentOk | Should -Be $true
            }
        }
    }
}

