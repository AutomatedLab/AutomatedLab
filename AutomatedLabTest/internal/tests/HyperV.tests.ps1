param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) HyperV" -Tag HyperV {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role HyperV).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'HyperV'}).Count
        }

        foreach ($vm in (Get-LabVm -Role HyperV))
        {
            It "$vm should have exposed virtualization extension" -Skip:$(-not (Test-IsAdministrator)) {
                (Get-Vm -Name $vm | Get-VMProcessor).ExposeVirtualizationExtensions | Should -Be $true
            }

            It "$vm should have Hyper-V feature installed" {
                (Get-LabWindowsFeature -ComputerName $vm -FeatureName Hyper-V -NoDisplay).Installed | Should -Be $true
            }
        }
    }
}
