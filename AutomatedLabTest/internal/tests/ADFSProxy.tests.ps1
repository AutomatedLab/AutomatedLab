param
(
    [Parameter()]
    [AutomatedLab.Lab]
    $Lab = $global:pesterLab
)

Describe "$($Lab.Name) ADFSProxy" -Tag ADFSProxy {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role ADFSProxy).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'ADFSProxy'}).Count
        }
    }
}
