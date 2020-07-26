Describe "[$($Lab.Name)] Routing" -Tag Routing {
Context "Role deployment successful" {
        It "[Routing] Should return the correct amount of machines" {
            (Get-LabVm -Role Routing).Count | Should -Be $(Get-Lab).Machines.Where({$_.Roles.Name -contains 'Routing'}).Count
        }

        foreach ($vm in (Get-LabVm -Role Routing))
        {
            It "[$vm] Should have Routing feature installed" -TestCases @{vm = $vm} {
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName Routing, RSAT-RemoteAccess -NoDisplay).Installed | Should -Not -Contain $false
            }

            It "[$vm] Should be connected to the internet" -TestCases @{vm = $vm} {
                Test-LabMachineInternetConnectivity -ComputerName $vm
            }
        }
    }
}

