param
(
    [Parameter(Mandatory)]
    [AutomatedLab.Lab]
    $Lab
)

Describe "$($Lab.Name) DSCPullServer" -Tag DSCPullServer {

    Context "Role deployment successful" {
        It "Should return the correct amount of machines" {
            (Get-LabVm -Role DSCPullServer).Count | Should -Be $Lab.Machines.Where({$_.Roles.Name -contains 'DSCPullServer'}).Count
        }
    }
}
