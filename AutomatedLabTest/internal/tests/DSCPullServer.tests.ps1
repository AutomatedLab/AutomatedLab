Describe "[$($Lab.Name)] DSCPullServer" -Tag DSCPullServer {
    Context "Role deployment successful" {
        It "[DSCPullServer] Should return the correct amount of machines" {
            (Get-LabVM -Role DSCPullServer).Count | Should -Be $(Get-Lab).Machines.Where( { $_.Roles.Name -contains 'DSCPullServer' }).Count
        }

        foreach ($vm in (Get-LabVM -Role DSCPullServer))
        {
            It "[$vm] should have all required Pull Server features installed" -TestCases @{
                vm = $vm
            } {            
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName DSC-Service -NoDisplay).Installed | Should -Not -Contain $false
            }

            It "[$vm] Pull Server DSC config should exist" -TestCases @{vm = $vm} {
                $config = Get-DscConfiguration -CimSession (New-LabCimSession -ComputerName $vm) -ErrorAction SilentlyContinue
                $config.ConfigurationName | Sort-Object -Unique | Should -Be 'SetupDscPullServer'
            }

            It "[$vm] Pull Server DSC config should be converged" -TestCases @{vm = $vm} {
                Test-DscConfiguration -CimSession (New-LabCimSession -ComputerName $vm) -ErrorAction SilentlyContinue | Should -Be $true
            }

            It "[$vm] Endpoint should be accessible" -TestCases @{vm = $vm} {
                    Invoke-LabCommand -ComputerName $vm -ScriptBlock {
                        if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
                        {
                            Write-Verbose -Message 'Adding support for TLS 1.2'
                            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
                        }
                        $uri = (Get-DscConfiguration -ErrorAction SilentlyContinue | Where-Object -Property CimClassName -eq 'DSC_xDscWebService').DscServerUrl                
                        Invoke-RestMethod -Method Get -Uri $uri -UseBasicParsing -ErrorAction SilentlyContinue
                    } -PassThru -NoDisplay | Should -Not -BeNullOrEmpty
            }
        }
    }
}

