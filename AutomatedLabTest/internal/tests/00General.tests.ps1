Describe "[$($Lab.Name)] General" -Tag General {
    Context "Lab deployment successful" {
            It "[<LabName>] Should return the correct amount of machines" -TestCases @(@{Lab = $Lab; LabName = $Lab.Name}) {
                $machines = if ($Lab.DefaultVirtualizationEngine -eq 'Azure')
                {
                    Get-LWAzureVm -ComputerName (Get-LabVm).ResourceName
                }
                elseif ($Lab.DefaultVirtualizationEngine -eq 'HyperV')
                {
                    Get-LWHyperVVm -Name (Get-LabVm -IncludeLinux).ResourceName
                }

                $machines.Count | Should -Be $lab.Machines.Count
            }
        }
    }
    
    