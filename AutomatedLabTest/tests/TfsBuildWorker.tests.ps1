Describe "[$($Lab.Name)] TfsBuildWorker" -Tag TfsBuildWorker {
    Context "Role deployment successful" {
        It "[TfsBuildWorker] Should return the correct amount of machines" {
            (Get-LabVM -Role TfsBuildWorker).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'TfsBuildWorker' }).Count
        }

        foreach ($vm in (Get-LabVM -Role TfsBuildWorker))
        {
            $role = $vm.Roles | Where-Object Name -eq TfsBuildWorker            
            if ($role.Properties.ContainsKey('Organisation') -and $role.Properties.ContainsKey('PAT'))
            {
                $tfsServer = 'dev.azure.com'
            }
            elseif ($role.Properties.ContainsKey('TfsServer'))
            {
                $tfsServer = Get-LabVM -ComputerName $role.Properties['TfsServer'] -ErrorAction SilentlyContinue
            }

            if (-not $tfsServer)
            {
                $tfsServer = Get-LabVM -Role Tfs2015, Tfs2017, Tfs2018, AzDevOps | Select-Object -First 1
            }

            It "[$vm] Should have build worker installed" -TestCases @{ 
                vm        = $vm
                tfsServer = $tfsServer
            } {
                $test = Test-LabTfsEnvironment -SkipServer -ComputerName $tfsServer -NoDisplay
                $test.BuildWorker[$vm.Name].WorkerDeploymentOk | Should -Not -Be $false
            }
        }
    }
}

